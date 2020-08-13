import Flynn
import ArgumentParser
import Foundation

// The actors work like this:
//
//  Audio ------> State
//    \           /
//     \         /
//      \       /
//       V     V
//        Lights
//
// Audio: Uses portaudio to pass audio through from mic to speakers. Gathers
//        statistical information used by Lights and State
// State: Changes light performances based on events detected in the audio
//        stream (such as when songs change or Alexa speaks)
// Lights: does pretty things with the RGB lighting on the jukebox

print("Jukebox - main")

let lights = Lights("jukebox.local", 7890)
let state = State(lights)
let audio = Audio(lights, state)

while true {
    sleep(1)
}
