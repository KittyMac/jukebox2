import Flynn

class Lights: Actor {

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        let stats: AudioStats = args[x:0]
        print(stats.peakAmplitude)
    }

}
