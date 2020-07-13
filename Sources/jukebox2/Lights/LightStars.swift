import Flynn
import Socket
import Foundation

class LightStars: LightVisual {

    required init() { }

    func update(_ channel: Channel, _ stats: AudioStats) {
        if channel.channelID == 0 {
            updateChannel0(stats, channel, channel.particles)
        } else {
            updateChannel1(stats, channel, channel.particles)
        }
    }

    private var frame = 0
    func updateChannel0(_ stats: AudioStats, _ channel: Channel, _ particles: ParticleEngine) {

        let colorA = Vec3(1.0, 1.0, 1.0)
        let colorB = Vec3(0.0, 0.0, 1.0)

        if stats.normalizedPeakToPeakAmplitude > 2.0 {
            frame = 3
        }

        if frame > 0 {
            frame -= 1
        }

        let color = (frame > 0) ? colorB : colorA

        let lightsDeltaX = abs(channel.locations[1].x - channel.locations[0].x)

        let fullVelocity = lightsDeltaX
        let halfVelocity = lightsDeltaX

        particles.spawn(position: Vec2(127.0, 128.0),
                        startVelocity: Vec2(fullVelocity, 0.0),
                        endValocity: Vec2(halfVelocity, 0.0),
                        startColor: color,
                        endColor: color,
                        startSize: 1,
                        endSize: 1,
                        lifeSpan: 5.75)

        particles.spawn(position: Vec2(127.0, 128.0),
                        startVelocity: Vec2(-fullVelocity, 0.0),
                        endValocity: Vec2(-halfVelocity, 0.0),
                        startColor: color,
                        endColor: color,
                        startSize: 1,
                        endSize: 1,
                        lifeSpan: 5.75)
    }

    func updateChannel1(_ stats: AudioStats, _ channel: Channel, _ particles: ParticleEngine) {

        if stats.normalizedPeakToPeakAmplitude >= 2.0 {
            particles.spawn(position: channel.locations.randomElement()!,
                            startVelocity: Vec2(),
                            endValocity: Vec2(),
                            startColor: Vec3(1.0, 1.0, 1.0),
                            endColor: Vec3(0.0, 0.0, 0.0),
                            startSize: 8,
                            endSize: 4,
                            lifeSpan: 8.0)
        }
    }
}
