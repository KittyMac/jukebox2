import Flynn
import Socket
import Foundation

// swiftlint:disable identifier_name

class LightPalms: LightVisual {
    private var updateFrameRate: Float = 1.0 / 60.0
    private var anim: Float = 0.0

    func update(_ channel: Channel, _ stats: AudioStats) {
        anim += Float(updateFrameRate)

        if channel.channelID == 0 {
            updateChannel0(stats, channel.particles)
        } else {
            updateChannel1(stats, channel, channel.particles)
        }
    }

    func updateChannel0(_ stats: AudioStats, _ particles: ParticleEngine) {

        let f = anim.truncatingRemainder(dividingBy: 1.0)
        let x = (f * 300) - 22

        particles.spawn(position: Vec2(x, 128.0),
                        startVelocity: Vec2(),
                        endValocity: Vec2(),
                        startColor: Vec3(1, 1, 1),
                        endColor: Vec3(0, 0, 1),
                        startSize: 8,
                        endSize: 8,
                        lifeSpan: 6.0)
    }

    func updateChannel1(_ stats: AudioStats, _ channel: Channel, _ particles: ParticleEngine) {
        
        let startColor = Vec3(randf() * 0.2, randf() * 0.2, randf() * 0.2)
        let size = 48.0 + stats.normalizedPeakAmplitude * 48.0
        let speed = stats.normalizedPeakAmplitude * 8.0 + 2.0

        let velocity = Vec2.rotate(Vec2(speed, 0.0), randf() * Float.pi * 4.0)

        particles.spawn(position: Vec2(126, 126),
                        startVelocity: velocity,
                        endValocity: velocity,
                        startColor: startColor,
                        endColor: startColor,
                        startSize: size,
                        endSize: size,
                        lifeSpan: randf() * 4.0 + 0.5)
    }
}
