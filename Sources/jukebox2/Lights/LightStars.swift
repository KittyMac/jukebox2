import Flynn
import Socket
import Foundation

class LightStars: LightVisual {
    func update(_ channel: Channel, _ stats: AudioStats) {
        if channel.channelID == 0 {
            updateChannel0(stats, channel.particles)
        } else {
            updateChannel1(stats, channel, channel.particles)
        }
    }

    func updateChannel0(_ stats: AudioStats, _ particles: ParticleEngine) {

        let value = stats.normalizedPeakAmplitude * 0.3
        let startColor = Vec3(value, value, value)
        let endColor = Vec3(0.0, 0.0, value)

        particles.spawn(position: Vec2(127.0, 128.0),
                        startVelocity: Vec2(3.95, 0.0),
                        endValocity: Vec2(0.0, 0.0),
                        startColor: startColor,
                        endColor: endColor,
                        startSize: 8,
                        endSize: 8,
                        lifeSpan: 5.55)

        particles.spawn(position: Vec2(127.0, 128.0),
                        startVelocity: Vec2(-3.95, 0.0),
                        endValocity: Vec2(0.0, 0.0),
                        startColor: startColor,
                        endColor: endColor,
                        startSize: 8,
                        endSize: 8,
                        lifeSpan: 5.55)
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
