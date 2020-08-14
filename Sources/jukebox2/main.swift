import Flynn
import ArgumentParser
import Foundation
import Pony

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

    print("======================================")
    print("Total Memory: \(pony_max_memory() / (1024 * 1024)) MB")
    print(audio.unsafeStatus)
    print(lights.unsafeStatus)
    print(state.unsafeStatus)
    print("======================================")

    sleep(60 * 30)
}
