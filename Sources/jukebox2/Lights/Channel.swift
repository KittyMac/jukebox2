import Flynn
import Socket
import Foundation

class Channel {
    let channelID: Int
    let numPixels: Int
    var pixels: [UInt8]
    var locations: [Vec2]

    init(_ channelID: Int, _ numPixels: Int, _ locationsClosure: (inout [Vec2]) -> Void) {
        self.channelID = channelID
        self.numPixels = numPixels

        pixels = [UInt8](repeating: 0, count: numPixels * 3 + 4)
        pixels[0] = UInt8(channelID)
        pixels[1] = 0
        pixels[2] = UInt8((numPixels * 3) / 256)
        pixels[3] = UInt8((numPixels * 3) % 256)

        locations = Array(repeating: Vec2(), count: numPixels)
        locationsClosure(&locations)
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

    func apply(_ particles: ParticleEngine) {
        for idx in 0..<numPixels {
            let color = particles.lookup(locations[idx])
            pixels[4 + idx * 3 + 0] = UInt8(color.r * 255)
            pixels[4 + idx * 3 + 1] = UInt8(color.g * 255)
            pixels[4 + idx * 3 + 2] = UInt8(color.b * 255)
        }
    }
}