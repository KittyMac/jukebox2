import Flynn
import Socket
import Foundation

// swiftlint:disable line_length

extension Socket {
    @discardableResult
    func setTCPNoDelay() -> Bool {
        var value: Int32 = 1
        return (setsockopt(self.socketfd, Int32(IPPROTO_TCP), Int32(TCP_NODELAY), &value, UInt32(MemoryLayout<Int32>.size)) == 0)
    }
}

class Lights: Actor {

    private let host: String
    private let port: Int32

    private var socket: Socket?

    // array contain the pixel brights for pixels for each channel. the first four bytes are
    // reserved for the OpenPixelControl message header
    private var channel0 = Channel(0, 59) { (locations) in
        locations = [
            Vec2(11+4*0, 128), Vec2(11+4*1, 128), Vec2(11+4*2, 128), Vec2(11+4*3, 128), Vec2(11+4*4, 128), Vec2(11+4*5, 128), Vec2(11+4*6, 128), Vec2(11+4*7, 128), Vec2(11+4*8, 128), Vec2(11+4*9, 128),
            Vec2(11+4*10, 128), Vec2(11+4*11, 128), Vec2(11+4*12, 128), Vec2(11+4*13, 128), Vec2(11+4*14, 128), Vec2(11+4*15, 128), Vec2(11+4*16, 128), Vec2(11+4*17, 128), Vec2(11+4*18, 128), Vec2(11+4*19, 128),
            Vec2(11+4*20, 128), Vec2(11+4*21, 128), Vec2(11+4*22, 128), Vec2(11+4*23, 128), Vec2(11+4*24, 128), Vec2(11+4*25, 128), Vec2(11+4*26, 128), Vec2(11+4*27, 128), Vec2(11+4*28, 128), Vec2(11+4*29, 128),
            Vec2(11+4*30, 128), Vec2(11+4*31, 128), Vec2(11+4*32, 128), Vec2(11+4*33, 128), Vec2(11+4*34, 128), Vec2(11+4*35, 128), Vec2(11+4*36, 128), Vec2(11+4*37, 128), Vec2(11+4*38, 128), Vec2(11+4*39, 128),
            Vec2(11+4*40, 128), Vec2(11+4*41, 128), Vec2(11+4*42, 128), Vec2(11+4*43, 128), Vec2(11+4*44, 128), Vec2(11+4*45, 128), Vec2(11+4*46, 128), Vec2(11+4*47, 128), Vec2(11+4*48, 128), Vec2(11+4*49, 128),
            Vec2(11+4*50, 128), Vec2(11+4*51, 128), Vec2(11+4*52, 128), Vec2(11+4*53, 128), Vec2(11+4*54, 128), Vec2(11+4*55, 128), Vec2(11+4*56, 128), Vec2(11+4*57, 128), Vec2(11+4*58, 128)
        ]
    }
    private var channel1 = Channel(1, 57) { (locations) in
        locations = [
            Vec2(0+32*0, 0+32*0), Vec2(0+32*0, 0+32*1), Vec2(0+32*0, 0+32*2), Vec2(0+32*0, 0+32*3), Vec2(0+32*0, 0+32*4), Vec2(0+32*0, 0+32*5), Vec2(0+32*0, 0+32*6), Vec2(0+32*0, 0+32*7),
            Vec2(0+32*1, 0+32*7), Vec2(0+32*1, 0+32*6), Vec2(0+32*1, 0+32*5), Vec2(0+32*1, 0+32*4), Vec2(0+32*1, 0+32*3), Vec2(0+32*1, 0+32*2), Vec2(0+32*1, 0+32*1), Vec2(0+32*1, 0+32*0),
            Vec2(0+32*2, 0+32*0), Vec2(0+32*2, 0+32*1), Vec2(0+32*2, 0+32*2), Vec2(0+32*2, 0+32*3), Vec2(0+32*2, 0+32*4), Vec2(0+32*2, 0+32*5), Vec2(0+32*2, 0+32*6), Vec2(0+32*2, 0+32*7),
            Vec2(0+32*3, 0+32*7), Vec2(0+32*3, 0+32*6), Vec2(0+32*3, 0+32*5), Vec2(0+32*3, 0+32*4), Vec2(0+32*3, 0+32*3), Vec2(0+32*3, 0+32*2), Vec2(0+32*3, 0+32*1), Vec2(0+32*3, 0+32*0),
            Vec2(0+32*4, 0+32*0), Vec2(0+32*4, 0+32*1), Vec2(0+32*4, 0+32*2), Vec2(0+32*4, 0+32*3), Vec2(0+32*4, 0+32*4), Vec2(0+32*4, 0+32*5), Vec2(0+32*4, 0+32*6), Vec2(0+32*4, 0+32*7),
            Vec2(0+32*5, 0+32*7), Vec2(0+32*5, 0+32*6), Vec2(0+32*5, 0+32*5), Vec2(0+32*5, 0+32*4), Vec2(0+32*5, 0+32*3), Vec2(0+32*5, 0+32*2), Vec2(0+32*5, 0+32*1), Vec2(0+32*5, 0+32*0),
            Vec2(0+32*6, 0+32*0), Vec2(0+32*6, 0+32*1), Vec2(0+32*6, 0+32*2), Vec2(0+32*6, 0+32*3), Vec2(0+32*6, 0+32*4), Vec2(0+32*6, 0+32*5), Vec2(0+32*6, 0+32*6), Vec2(0+32*6, 0+32*7),
            Vec2(999, 999)
        ]

    }

    init(_ host: String, _ port: Int32) {
        self.host = host
        self.port = port

        super.init()
        connectToServer()
    }

    private func connectToServer() {
        socket?.close()
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

    private func _beClose() {
        self.socket?.close()
    }
    public func beClose() {
        unsafeSend(_beClose)
    }

    // MARK: - Visuals

    private var previousTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var updateTime: TimeInterval = 0
    private var updateFrameRate: TimeInterval = 1.0 / 60.0

    private var anim: Float = 0.0
    private func _beSetAudioStats(_ stats: AudioStats) {
        let currentTime = ProcessInfo.processInfo.systemUptime
        let deltaTime = (currentTime - previousTime)
        updateTime += deltaTime
        previousTime = currentTime

        let didUpdate = updateTime > updateFrameRate
        while updateTime > updateFrameRate {
            updateTime -= updateFrameRate

            channel0.update(stats)
            channel1.update(stats)
        }

        if didUpdate {
            if let socket = socket {
                do {
                    try channel0.send(socket)
                    try channel1.send(socket)
                } catch {
                    print("connection to fadecandy server lost, reconnecting...")
                    connectToServer()
                }
            }
        }
    }

    private func _beSetVisual(_ channelIdx: Int, _ visual: LightVisual.Type) {
        switch channelIdx {
        case 0:
            self.channel0.visual = visual.init()
        case 1:
            self.channel1.visual = visual.init()
        default:
            break
        }
    }

    private func _beSetBrightness(_ brightness: Float) {
        self.channel0.targetBrightness = brightness
        self.channel1.targetBrightness = brightness
    }

}

// MARK: - Autogenerated by FlynnLint
// Contents of file after this marker will be overwritten as needed

extension Lights {

    @discardableResult
    public func beClose() -> Self {
        unsafeSend(_beClose)
        return self
    }
    @discardableResult
    public func beSetAudioStats(_ stats: AudioStats) -> Self {
        unsafeSend { self._beSetAudioStats(stats) }
        return self
    }
    @discardableResult
    public func beSetVisual(_ channelIdx: Int, _ visual: LightVisual.Type) -> Self {
        unsafeSend { self._beSetVisual(channelIdx, visual) }
        return self
    }
    @discardableResult
    public func beSetBrightness(_ brightness: Float) -> Self {
        unsafeSend { self._beSetBrightness(brightness) }
        return self
    }

}
