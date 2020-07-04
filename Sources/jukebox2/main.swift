import Flynn
import ArgumentParser

// The actors work like this:
//
//  AudioIn ------> AudioOut
//    \
//     \
//      \
//       V
//     Lights
//
// AudioIn: reads chunks of audio data from the mic, sends the data to
//          AudioOut and Lights
// AudioOut: writes the chunks of audio data to the speakers
// Lights: does pretty things with the lights given the audio data

class Main: Actor {
    private let audioIn: AudioIn
    private let audioOut: AudioOut
    private let lights: Lights

    override init() {
        audioOut = AudioOut()
        lights = Lights()
        //audioIn = AudioIn(audioOut, lights)
        audioIn = AudioIn()
    }

    lazy var beRun = Behavior(self, _beRun)
    private func _beRun(_: BehaviorArgs) {

    }
}

Main().beRun()

Flynn.shutdown()
