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

    private let host: String
    private let port: Int32

    private var socket: Socket?
    private let particles: ParticleEngine

    // array contain the pixel brights for pixels for each channel. the first four bytes are
    // reserved for the OpenPixelControl message header
    private var channel0 = Channel(0, 59) { (locations) in
        for idx in 0..<59 {
            locations[idx] = Vec2(11.0 + 4.0 * Float(idx), 128.0)
        }
    }
    private var channel1 = Channel(1, 57) { (locations) in
        var idx = 0
        for xPos in 0..<7 {
            for yPos in 0..<8 {
                if xPos % 1 == 0 {
                    locations[idx] = Vec2(0.0 + 32.0 * Float(xPos), 0.0 + 32.0 * Float(yPos))
                } else {
                    locations[idx] = Vec2(0.0 + 32.0 * Float(xPos), 0.0 + 32.0 * Float(7 / yPos))
                }
                idx += 1
            }
        }
    }

    init(_ host: String, _ port: Int32) {

        particles = ParticleEngine()

        self.host = host
        self.port = port

        super.init()
        connectToServer()
    }

    private func connectToServer() {
        if socket == nil || socket?.isConnected == false {
            do {
                let signature = try Socket.Signature(protocolFamily: .inet,
                                                     socketType: .stream,
                                                     proto: .tcp,
                                                     hostname: host,
                                                     port: port)
                socket = try Socket.create(connectedUsing: signature!)
                socket?.setTCPNoDelay()
            } catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error creating fadecandy socket connection")
                    return
                }
                print("Error connecting to fadecandy server: \(socketError.description)")
            }
        }
    }

    lazy var beClose = Behavior(self) { [unowned self] (_: BehaviorArgs) in
        self.socket?.close()
    }

    private func floatToUInt8(_ value: Float) -> UInt8 {
        return UInt8(max(min(value * 255, 255), 0))
    }

    private var anim: Float = 0.0
    private func _beSetAudioStats(_ args: BehaviorArgs) {
        let stats: AudioStats = args[x:0]

        anim += 0.01

        let xVal = 128.0 + sin(anim * 4.0) * (128.0 + 64.0)

        particles.spawn(position: Vec2(xVal, 128),
                        startVelocity: Vec2(),
                        endValocity: Vec2(),
                        startColor: Vec3(1.0, 0.0, 0.0),
                        endColor: Vec3(0.15, 0.15, 0.0),
                        startSize: 48,
                        endSize: 48,
                        lifeSpan: 1.1)

        particles.update()
        particles.update()

        channel0.apply(particles)
        channel1.apply(particles)

        if let socket = socket {
            channel0.send(socket)
            channel1.send(socket)
        }
    }

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        self._beSetAudioStats(args)
    }

}
