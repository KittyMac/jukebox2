import Flynn
import portaudio
import libportaudio
import Foundation

// swiftlint:disable function_parameter_count
// swiftlint:disable function_body_length

private func bridge<T: AnyObject>(obj: T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

private func bridge<T: AnyObject>(ptr: UnsafeMutableRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

private func passthroughAudio(_ inputBuffer: UnsafeRawPointer?,
                              _ outputBuffer: UnsafeMutableRawPointer?,
                              _ framesPerBuffer: UInt,
                              _ timeInfo: UnsafePointer<PaStreamCallbackTimeInfo>?,
                              _ statusFlags: PaStreamCallbackFlags,
                              _ userData: UnsafeMutableRawPointer?) -> Int32 {
    // In portaudio, this is a C callback in which it is VERY IMPORTANT not to do
    // any lengthy operations in (such as malloc, init objects, etc). So we limit
    // this function to the following barebones tasks:
    // 1. copy the input stream to the output stream
    // 2. calculate critical audio stats for other systems to interpret
    // 3. pass this information to the audio actor
    let audioActor: Audio = bridge(ptr: userData!)

    if let inputBuffer = inputBuffer {
        let inPtr = inputBuffer.assumingMemoryBound(to: Float.self)
        if let outputBuffer = outputBuffer {
            let outPtr = outputBuffer.assumingMemoryBound(to: Float.self)

            var average: Float = 0.0
            var maxAmplitude: Float = 0.0
            var minAmplitude: Float = 0.0

            for idx in 0..<Int(framesPerBuffer) {
                let value = inPtr[idx]
                maxAmplitude = max(maxAmplitude, value)
                minAmplitude = min(minAmplitude, value)
                average += value
                outPtr[idx] = value
            }

            let peakAmplitude = max(maxAmplitude, abs(minAmplitude))
            let peakToPeakAmplitude = maxAmplitude - minAmplitude

            average /= Float(framesPerBuffer)

            let stats = AudioStats(average: average,
                                   peakAmplitude: peakAmplitude,
                                   peakToPeakAmplitude: peakToPeakAmplitude)

            audioActor.beSetAudioStats(stats)
        }
    }
    return Int32(paContinue.rawValue)
}

struct AudioStats {
    var average: Float
    var peakAmplitude: Float
    var peakToPeakAmplitude: Float

    var normalize: Float = 0
    var normalizedPeakAmplitude: Float = 0
    var normalizedPeakToPeakAmplitude: Float = 0
}

extension AudioStats {
    init() {
        average = 0
        peakAmplitude = 0
        peakToPeakAmplitude = 0
    }
}

class Audio: Actor {
    private let state: State
    private let lights: Lights

    private let portaudio: PortAudio
    private var stream: PortAudioStream?

    private var runningPeakAmplitude: Float = 0.0

    private var lastAudioStatsTime: TimeInterval

    init(_ lights: Lights, _ state: State) {
        self.state = state
        self.lights = lights

        portaudio = PortAudio()

        lastAudioStatsTime = ProcessInfo.processInfo.systemUptime

        super.init()

        unsafeCoreAffinity = .onlyPerformance
        unsafePriority = 99

        var outputDevice: PaDeviceInfo?
        var outputDeviceIdx: Int32?
        var inputDevice: PaDeviceInfo?
        var inputDeviceIdx: Int32?

        if let (defaultOutputDevice, defaultOutputDeviceIdx) = portaudio.defaultOutputDevice {
            outputDevice = defaultOutputDevice
            outputDeviceIdx = defaultOutputDeviceIdx
        }

        if let (defaultInputDevice, defaultInputDeviceIdx) = portaudio.defaultInputDevice {
            inputDevice = defaultInputDevice
            inputDeviceIdx = defaultInputDeviceIdx
        }

        var deviceIdx: Int32 = 0
        for device in portaudio.devices {
            if String(cString: device.name).hasPrefix("USB Audio Device") {
                outputDevice = device
                outputDeviceIdx = deviceIdx

                inputDevice = device
                inputDeviceIdx = deviceIdx
            }
            deviceIdx += 1
        }

        if  let outputDevice = outputDevice,
            let outputDeviceIdx = outputDeviceIdx,
            let inputDevice = inputDevice,
            let inputDeviceIdx = inputDeviceIdx {

            let numChannels = inputDevice.maxInputChannels < outputDevice.maxOutputChannels ?
                inputDevice.maxInputChannels : outputDevice.maxOutputChannels

            inputDevice.print(inputDeviceIdx)
            outputDevice.print(outputDeviceIdx)

            var inputParameters = PaStreamParameters()
            inputParameters.device = inputDeviceIdx
            inputParameters.channelCount = numChannels
            inputParameters.sampleFormat = paFloat32
            inputParameters.suggestedLatency = inputDevice.defaultHighInputLatency
            inputParameters.hostApiSpecificStreamInfo = nil

            var outputParameters = PaStreamParameters()
            outputParameters.device = outputDeviceIdx
            outputParameters.channelCount = numChannels
            outputParameters.sampleFormat = paFloat32
            outputParameters.suggestedLatency = outputDevice.defaultHighOutputLatency
            outputParameters.hostApiSpecificStreamInfo = nil

            let sampleRate: Double = inputDevice.defaultSampleRate
            let framePerBuffer: Int = 128

            let streamFinished: PaStreamFinishedClosure = { (userData) in
                print("audio stream unexpectedly ended, exiting...")
                exit(1)
            }

            stream = portaudio.openStream(&inputParameters,
                                          &outputParameters,
                                          sampleRate,
                                          framePerBuffer,
                                          bridge(obj: self),
                                          passthroughAudio,
                                          streamFinished)
            if let stream = stream {
                stream.start()
            }

            //Flynn.Timer(timeInterval: 1.0, repeats: true, beConfirmAudioIsAlive, [])

        } else {
            print("no audio devices detected, exiting...")
            exit(1)
        }
    }

    private func _beSetAudioStats(_ stats: AudioStats) {
        var modStats = stats

        if runningPeakAmplitude == 0 {
            runningPeakAmplitude = modStats.peakAmplitude
        }

        runningPeakAmplitude += (modStats.peakAmplitude - runningPeakAmplitude) * 0.00123

        var normalize = 1.0 / runningPeakAmplitude
        if normalize < 1.0 {
            normalize = 1.0
        }
        if normalize > 100.0 {
            normalize = 100.0
        }

        modStats.normalize = normalize
        modStats.normalizedPeakAmplitude = modStats.peakAmplitude * normalize
        modStats.normalizedPeakToPeakAmplitude = modStats.peakToPeakAmplitude * normalize

        lights.beSetAudioStats(modStats)
        state.beSetAudioStats(modStats)

        lastAudioStatsTime = ProcessInfo.processInfo.systemUptime
    }

    private func _beStop() {
        if let stream = self.stream {
            stream.stop()
            stream.close()
        }
    }
    public func beStop() {
        unsafeSend(_beStop)
    }

    /*
    lazy var beConfirmAudioIsAlive = Behavior(self) { [unowned self] (_: BehaviorArgs) in
        let currentTime = ProcessInfo.processInfo.systemUptime
        //print("delta: \(currentTime - self.lastAudioStatsTime), \(self.unsafeMessagesCount)")
        if currentTime - self.lastAudioStatsTime > 5.0 {
            print("Have not received any audio signals for 5 seconds, exiting...")
            exit(1)
        }
    }
 */
}

// MARK: - Autogenerated by FlynnLint
// Contents of file after this marker will be overwritten as needed

extension Audio {

    @discardableResult
    public func beSetAudioStats(_ stats: AudioStats) -> Self {
        unsafeSend { self._beSetAudioStats(stats) }
        return self
    }
    @discardableResult
    public func beStop() -> Self {
        unsafeSend(_beStop)
        return self
    }

}
