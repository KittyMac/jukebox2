import Flynn
import Socket
import Foundation

class LightTheater: LightVisual {
    private var updateFrameRate: Float = 1.0 / 60.0

    private var frame = 0

    private var numLights = 0

    func update(_ channel: Channel, _ particles: ParticleEngine) {
        frame += 1
        numLights = channel.numPixels

        if channel.channelID == 0 {
            updateChannel0(channel, particles)
        } else {
            updateChannel1(channel, particles)
        }
    }

    func updateChannel0(_ channel: Channel, _ particles: ParticleEngine) {

        let lightsDeltaX = abs(channel.locations[1].x - channel.locations[0].x)
        var lightsStartX = channel.locations[0].x - lightsDeltaX * 1
        var color = Vec3(1.0, 0.0, 1.0)

        if frame % 10 < 5 {
            lightsStartX = channel.locations[0].x - lightsDeltaX * 2
            color = Vec3(0.0, 0.0, 1.0)
        }

        particles.spawn(position: Vec2(lightsStartX, channel.locations[0].y),
                        startVelocity: Vec2(lightsDeltaX * 2, 0.0),
                        endValocity: Vec2(lightsDeltaX * 2, 0.0),
                        startColor: color,
                        endColor: color,
                        startSize: 2,
                        endSize: 2,
                        lifeSpan: 3.4)
    }

    func updateChannel1(_ channel: Channel, _ particles: ParticleEngine) {
        let xPos = randf() * 255

        for idx in 0..<3 {
            particles.spawn(position: Vec2(xPos, 255 + Float(idx) * 16),
                            startVelocity: Vec2(0.0, -16.0),
                            endValocity: Vec2(),
                            startColor: Vec3(randf(), randf(), 1.0),
                            endColor: Vec3(0.0, 0.0, 0.0),
                            startSize: 18,
                            endSize: 18,
                            lifeSpan: 4.0)
        }
    }
}
