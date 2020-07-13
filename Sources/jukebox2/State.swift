import Flynn
import Foundation

class State: Actor {
    // Responsible for changing the light visuals run by the lights
    // actor.  Each channel in Lights can be assigned a unique
    // visualization (LightStars, for example). We want to change
    // visuals "smartly", so this actor attempt to detect when
    // songs change and switch visuals then.
    //
    // This actor should also automatically dim the jukebox lights
    // after 11pm.

    private var allVisuals: [LightVisual.Type] = [ LightPalms.self,
                                                   LightStars.self,
                                                   LightTheater.self]

    private let lights: Lights

    init(_ lights: Lights) {
        self.lights = lights
        super.init()
    }

    private func switchVisuals() {
        let visual0 = (allVisuals.randomElement()!)
        let visual1 = (allVisuals.randomElement()!)

        self.lights.beSetVisual(0, visual0)
        self.lights.beSetVisual(1, visual1)
        self.lights.beSetBrightness(checkBrightness())
    }

    private func checkBrightness() -> Float {
        let calendar = Calendar.current
        let now = NSDate()
        let nowDateValue = now as Date

        let morning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: nowDateValue)
        let night = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: nowDateValue)

        if let morning = morning, let night = night {
            if nowDateValue >= morning && nowDateValue <= night {
                return 1.0
            }
        }
        return 0.75
    }

    private var startQuietTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var lastSwitchSongTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private func _beSetAudioStats(_ args: BehaviorArgs) {
        let stats: AudioStats = args[x:0]

        let currentTime = ProcessInfo.processInfo.systemUptime

        // We will assume there is a 3 seconds downtime between songs. This is obviously
        // not perfect, as songs with quiet moments will be detected as song change.
        if stats.peakToPeakAmplitude >= 0.025 {
            startQuietTime = currentTime
        }

        if currentTime - startQuietTime > 2.0 {
            if currentTime - lastSwitchSongTime > 30 {
                switchVisuals()
                print("switch songs!")
                lastSwitchSongTime = currentTime
            }
        }
    }

    lazy var beSetAudioStats = Behavior(self) { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter AudioStats - stats related to the audio buffer
        self._beSetAudioStats(args)
    }
}
