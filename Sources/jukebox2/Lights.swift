import Flynn
import Socket
import Foundation

extension Socket {
    @discardableResult
    func setTCPNoDelay() -> Bool {
        var value: Int32 = 1
        return (setsockopt(self.socketfd, IPPROTO_TCP, TCP_NODELAY, &value, UInt32(MemoryLayout<Int32>.size)) == 0)
    }
}

class Channel {
    let channelID: Int
    let numPixels: Int
    var pixels: [UInt8]

    init(_ channelID: Int, _ numPixels: Int) {
        self.channelID = channelID
        self.numPixels = numPixels

        pixels = [UInt8](repeating: 0, count: numPixels * 3 + 4)
        pixels[0] = UInt8(channelID)
        pixels[1] = 0
        pixels[2] = UInt8((numPixels * 3) / 256)
        pixels[3] = UInt8((numPixels * 3) % 256)
    }

    func send(_ socket: Socket) {
        _ = try? socket.write(from: pixels, bufSize: pixels.count)
    }

    func fill(_ white: UInt8) {
        fill(white, white, white)
    }

    func fill(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        for idx in 0..<numPixels {
            pixels[4 + idx * 3 + 0] = red
            pixels[4 + idx * 3 + 1] = green
            pixels[4 + idx * 3 + 2] = blue
        }
    }
}

class Lights: Actor {

    private let socket: Socket

    // array contain the pixel brights for pixels for each channel. the first four bytes are
    // reserved for the OpenPixelControl message header
    private var channel0 = Channel(0, 59)
    private var channel1 = Channel(1, 57)

    init(_ host: String, _ port: Int32) {

        do {
            // connect to the fadecandy server
            let signature = try Socket.Signature(protocolFamily: .inet,
                                                 socketType: .stream,
                                                 proto: .tcp,
                                                 hostname: host,
                                                 port: port)
            socket = try Socket.create(connectedUsing: signature!)

            socket.setTCPNoDelay()

            print("connected to fadecandy server")

        } catch let error {

            // See if it's a socket error or something else...
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error creating fadecandy socket connection")
                exit(1)
            }

            print("Error connecting to fadecandy server: \(socketError.description)")
            exit(1)
        }

        super.init()
    }

    lazy var beClose = Behavior(self) { [unowned self] (_: BehaviorArgs) in
        self.socket.close()
    }

    private func floatToUInt8(_ value: Float) -> UInt8 {
        return UInt8(max(min(value * 255, 255), 0))
    }

    private func _beSetAudioStats(_ args: BehaviorArgs) {
        let stats: AudioStats = args[x:0]

        let value = floatToUInt8(stats.normalizedPeakAmplitude)

        channel0.fill(value)

        channel0.send(socket)
        channel1.send(socket)
    }

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        self._beSetAudioStats(args)
    }

}
