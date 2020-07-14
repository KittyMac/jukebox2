import Flynn
import Socket
import Foundation

func crand() -> UInt32 {
	#if os(Linux)
		return UInt32(random())
	#else
		return arc4random()
	#endif
}

func randf() -> Float {
    return Float(crand() % 100000) / 100000.0
}

protocol LightVisual {
    init()
    func update(_ channel: Channel, _ stats: AudioStats)
}

class Channel {
    let channelID: Int
    let numPixels: Int
    var pixels: [UInt8]
    var locations: [Vec2]

    var visual: LightVisual
    let particles: ParticleEngine

    var currentBrightness: Float = 1.0
    var targetBrightness: Float = 1.0

    init(_ channelID: Int, _ numPixels: Int, _ locationsClosure: (inout [Vec2]) -> Void) {
        self.channelID = channelID
        self.numPixels = numPixels

        visual = LightTheater()
        particles = ParticleEngine()

        pixels = [UInt8](repeating: 0, count: numPixels * 3 + 4)
        pixels[0] = UInt8(channelID)
        pixels[1] = 0
        pixels[2] = UInt8((numPixels * 3) / 256)
        pixels[3] = UInt8((numPixels * 3) % 256)

        locations = Array(repeating: Vec2(), count: numPixels)
        locationsClosure(&locations)
    }

    func send(_ socket: Socket) {
        for idx in 0..<numPixels {
            let color = particles.lookup(locations[idx])
            pixels[4 + idx * 3 + 0] = UInt8(color.r * currentBrightness * 255)
            pixels[4 + idx * 3 + 1] = UInt8(color.g * currentBrightness * 255)
            pixels[4 + idx * 3 + 2] = UInt8(color.b * currentBrightness * 255)
        }

        _ = try? socket.write(from: pixels, bufSize: pixels.count)
    }

    func update(_ stats: AudioStats) {

        currentBrightness += (targetBrightness - currentBrightness) * 0.0123456

        visual.update(self, stats)
        particles.update()
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
