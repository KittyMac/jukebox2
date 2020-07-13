import Flynn
import Socket
import Foundation

func rand() -> UInt32 {
    return arc4random()
}

func randf() -> Float {
    return Float(arc4random() % 100000) / 100000.0
}

protocol LightVisual {
    func update(_ channel: Int, _ particles: ParticleEngine)
}
