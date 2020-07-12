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

class Lights: Actor {

    private let socket: Socket

    // array contain the pixel brights for pixels for each channel. the first four bytes are
    // reserved for the OpenPixelControl message header
    private lazy var channel0: [UInt8] = newChannel(0, 59)
    private lazy var channel1: [UInt8] = newChannel(1, 57)

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

        send(channel0)
        send(channel1)
    }

    private func newChannel(_ idx: Int, _ numPixels: Int) -> [UInt8] {
        var array = [UInt8](repeating: 0, count: numPixels * 3 + 4)
        array[0] = UInt8(idx)
        array[1] = 0
        array[2] = UInt8((numPixels * 3) / 256)
        array[3] = UInt8((numPixels * 3) % 256)
        return array
    }

    private func send(_ array: [UInt8]) {
        try? socket.write(from: array, bufSize: array.count)
    }

    private func sendTestPattern() {

    }

    lazy var beClose = Behavior(self) { [unowned self] (_: BehaviorArgs) in
        self.socket.close()
    }

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        let stats: AudioStats = args[x:0]
        //print(stats.peakAmplitude)
    }

}
