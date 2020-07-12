import Flynn
import portaudio
import libportaudio

// swiftlint:disable function_parameter_count

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
                minAmplitude = max(minAmplitude, value)
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

    private var audioStats = AudioStats()
    private var runningPeakAmplitude: Float = 0.0

    init(_ lights: Lights, _ state: State) {
        self.state = state
        self.lights = lights

        portaudio = PortAudio()

        super.init()

        if let (outputDevice, outputDeviceIdx) = portaudio.defaultOutputDevice,
            let (inputDevice, inputDeviceIdx) = portaudio.defaultInputDevice {

            let numChannels = inputDevice.maxInputChannels < outputDevice.maxOutputChannels ?
                inputDevice.maxInputChannels : outputDevice.maxOutputChannels

            inputDevice.print(inputDeviceIdx)
            outputDevice.print(outputDeviceIdx)

            var inputParameters = PaStreamParameters()
            inputParameters.device = inputDeviceIdx
            inputParameters.channelCount = numChannels
            inputParameters.sampleFormat = paFloat32
            inputParameters.suggestedLatency = inputDevice.defaultLowOutputLatency
            inputParameters.hostApiSpecificStreamInfo = nil

            var outputParameters = PaStreamParameters()
            outputParameters.device = outputDeviceIdx
            outputParameters.channelCount = numChannels
            outputParameters.sampleFormat = paFloat32
            outputParameters.suggestedLatency = outputDevice.defaultLowOutputLatency
            outputParameters.hostApiSpecificStreamInfo = nil

            let sampleRate: Double = inputDevice.defaultSampleRate
            let framePerBuffer: Int = 128

            stream = portaudio.openStream(&inputParameters,
                                          &outputParameters,
                                          sampleRate,
                                          framePerBuffer,
                                          bridge(obj: self),
                                          passthroughAudio,
                                          nil)
            if let stream = stream {
                stream.start()
            }

        } else {
            exit(1)
        }
    }

    private func _beSetAudioStats(_ args: BehaviorArgs) {
        var stats: AudioStats = args[x:0]

        if runningPeakAmplitude == 0 {
            runningPeakAmplitude = stats.peakAmplitude
        }

        runningPeakAmplitude += (stats.peakAmplitude - runningPeakAmplitude) * 0.000123

        var normalize = 1.0 / runningPeakAmplitude
        if normalize < 1.0 {
            normalize = 1.0
        }
        if normalize > 100.0 {
            normalize = 100.0
        }

        stats.normalize = normalize
        stats.normalizedPeakAmplitude = stats.peakAmplitude * normalize
        stats.normalizedPeakToPeakAmplitude = stats.peakToPeakAmplitude * normalize

        audioStats = stats
        lights.beSetAudioStats(stats)
    }

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        self._beSetAudioStats(args)
    }

    lazy var beStop = Behavior(self) { [unowned self] (_: BehaviorArgs) in
        if let stream = self.stream {
            stream.stop()
            stream.close()
        }
    }

}
