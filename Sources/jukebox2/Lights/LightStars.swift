import Flynn
import Socket
import Foundation

class LightStars: LightVisual {
    func update(_ channel: Channel, _ particles: ParticleEngine) {
        if channel.channelID == 0 {
            updateChannel0(channel, particles)
        } else {
            updateChannel1(channel, particles)
        }
    }

    func updateChannel0(_ channel: Channel, _ particles: ParticleEngine) {

        if rand() % 100 < 10 {
            particles.spawn(position: Vec2(127.0, 128.0),
                            startVelocity: Vec2(3.95, 0.0),
                            endValocity: Vec2(0.0, 0.0),
                            startColor: Vec3(1.0, 1.0, 1.0),
                            endColor: Vec3(0.0, 0.0, 1.0),
                            startSize: 8,
                            endSize: 8,
                            lifeSpan: 5.55)

            particles.spawn(position: Vec2(127.0, 128.0),
                            startVelocity: Vec2(-3.95, 0.0),
                            endValocity: Vec2(0.0, 0.0),
                            startColor: Vec3(1.0, 1.0, 1.0),
                            endColor: Vec3(0.0, 0.0, 1.0),
                            startSize: 8,
                            endSize: 8,
                            lifeSpan: 5.55)
        }
    }

    func updateChannel1(_ channel: Channel, _ particles: ParticleEngine) {

        if particles.numberOfParticles < 15 {
            if randf() < 0.1 {
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
}
