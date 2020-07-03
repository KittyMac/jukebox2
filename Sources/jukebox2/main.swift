import Flynn

// Our jukebox has two main functions:
// 1. read audio input from the microphone and stream it to the audio output
// 2. run the jukebox lights (using the wafeform processed by #1)
//
// To accomplish this, we will have a three actor system:
// 1. Main: provides setup and initialization
// 2. Lights: provides all things to do with lighting
// 3. Audio: provides all things to do with audio

class Main: Actor {
    private let audio = Audio()
    private let lights = Lights()
    
    
    lazy var beRun = Behavior(self, _beRun)
    private func _beRun(_: BehaviorArgs) {
        
    }
}

Main().beRun()

Flynn.shutdown()
