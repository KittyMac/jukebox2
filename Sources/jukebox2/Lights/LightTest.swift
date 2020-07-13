import Flynn
import Socket
import Foundation

class LightTest: LightVisual {
    private var updateFrameRate: Float = 1.0 / 60.0
    private var anim: Float = 0.0

    func update(_ channel: Channel, _ stats: AudioStats) {
        anim += Float(updateFrameRate)

        if channel.channelID == 0 {
            updateChannel0(channel.particles)
        } else {
            updateChannel1(channel.particles)
        }
    }

    func updateChannel0(_ particles: ParticleEngine) {
        let xVal = 128.0 + sin(anim * 4.0) * (128.0 + 64.0)

        particles.spawn(position: Vec2(xVal, 128),
                        startVelocity: Vec2(),
                        endValocity: Vec2(),
                        startColor: Vec3(1.0, 0.0, 0.0),
                        endColor: Vec3(0.15, 0.15, 0.0),
                        startSize: 48,
                        endSize: 48,
                        lifeSpan: 1.1)
    }

    func updateChannel1(_ particles: ParticleEngine) {
        particles.spawn(position: Vec2(randf() * 255, 0),
                        startVelocity: Vec2(0.0, randf() * 8.0),
                        endValocity: Vec2(),
                        startColor: Vec3(1.0, 0.0, 0.0),
                        endColor: Vec3(1.0, 1.0, 0.0),
                        startSize: 24,
                        endSize: 4,
                        lifeSpan: 4.0)
    }
}
