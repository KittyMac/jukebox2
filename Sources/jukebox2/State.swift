import Flynn

class State: Actor {
    private let lights: Lights

    init(_ lights: Lights) {
        self.lights = lights
    }
}
