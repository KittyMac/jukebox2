import Flynn
import Socket
import Foundation

// swiftlint:disable identifier_name
// swiftlint:disable function_parameter_count

extension Float {
    static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        return a + (t * (b - a))
    }
}

struct Vec2 {
    var x: Float = 0
    var y: Float = 0

    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    init() { }

    mutating func zero() {
        x = 0
        y = 0
    }

    mutating func clamp(_ minV: Float, _ maxV: Float) {
        x = max(minV, min(maxV, x))
        y = max(minV, min(maxV, y))
    }

    static func lerp(_ a: Vec2, _ b: Vec2, _ t: Float) -> Vec2 {
        return Vec2(Float.lerp(a.x, b.x, t),
                    Float.lerp(a.y, b.y, t))
    }

    static func add(_ a: Vec2, _ b: Vec2) -> Vec2 {
        return Vec2(a.x + b.x, a.y + b.y)
    }

    static func sqrDistance(_ a: Vec2, _ b: Vec2) -> Float {
        let dX = (b.x - a.x)
        let dY = (b.y - a.y)
        return (dX * dX) + (dY * dY)
    }
}

struct Vec3 {
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0

    var r: Float { get { return x } set { x = newValue } }
    var g: Float { get { return y } set { y = newValue } }
    var b: Float { get { return z } set { z = newValue } }

    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    init() { }

    mutating func zero() {
        x = 0
        y = 0
        z = 0
    }

    mutating func clamp(_ minV: Float, _ maxV: Float) {
        x = max(minV, min(maxV, x))
        y = max(minV, min(maxV, y))
        z = max(minV, min(maxV, z))
    }

    static func lerp(_ a: Vec3, _ b: Vec3, _ t: Float) -> Vec3 {
        return Vec3(Float.lerp(a.x, b.x, t),
                    Float.lerp(a.y, b.y, t),
                    Float.lerp(a.z, b.z, t))
    }
}

class Particle {
    var position = Vec2()

    var startVelocity = Vec2()
    var endValocity = Vec2()

    var startColor = Vec3()
    var endColor = Vec3()

    var startSize: Float = 48.0
    var endSize: Float = 48.0

    var lifeSpan: Float = 0.0
    var lifeNow: Float = 0.0

    func reset() {
        position = Vec2()
        startVelocity = Vec2()
        endValocity = Vec2()
        startColor = Vec3()
        endColor = Vec3()
        startSize = 48.0
        endSize = 48.0
        lifeSpan = 0.0
        lifeNow = 0.0
    }

    func alive() -> Bool {
        return lifeNow < lifeSpan
    }

    func t() -> Float {
        lifeNow / lifeSpan
    }

    func update(_ decay: Float) {
        let velocity = Vec2.lerp(startVelocity, endValocity, t())
        position = Vec2.add(position, velocity)
        lifeNow += decay
    }
}

class ParticleEngine {
    let maxParticles = 500
    var particles: [Particle] = []
    var lifeDecay: Float = 0.1
    var numberOfParticles = 0

    init() {
        for _ in 0..<maxParticles {
            particles.append(Particle())
        }
    }

    func spawn(position: Vec2,
               startVelocity: Vec2,
               endValocity: Vec2,
               startColor: Vec3,
               endColor: Vec3,
               startSize: Float,
               endSize: Float,
               lifeSpan: Float) {
        for p in particles {
            if p.alive() == false {
                p.position = position
                p.startVelocity = startVelocity
                p.endValocity = endValocity
                p.startColor = startColor
                p.endColor = endColor
                p.startSize = startSize
                p.endSize = endSize
                p.lifeSpan = lifeSpan
                p.lifeNow = 0.0
                return
            }
        }
    }

    func update() {
        numberOfParticles = 0
        for idx in 0..<particles.count {
            if particles[idx].alive() == true {
                numberOfParticles += 1
                particles[idx].update(lifeDecay)
            }
        }
    }

    func lookup(_ location: Vec2) -> Vec3 {
        var retColor = Vec3()
        for p in particles {
            if p.alive() == true {

                let size = Float.lerp(p.startSize, p.endSize, p.t())
                let color = Vec3.lerp(p.startColor, p.endColor, p.t())

                let sqrMaxDistance = size * size
                let sqrDistance = Vec2.sqrDistance(location, p.position)

                if sqrDistance < sqrMaxDistance {
                    let brightness = 1.0 - (sqrDistance / sqrMaxDistance)

                    retColor.r += color.r * brightness
                    retColor.g += color.g * brightness
                    retColor.b += color.b * brightness
                }
            }
        }

        retColor.clamp(0, 1)
        return retColor
    }
}
