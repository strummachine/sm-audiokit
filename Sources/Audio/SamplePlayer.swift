import Foundation
import AudioKit
import AVFoundation
import AudioKitEX
import CAudioKitEX

class SamplePlayer {
    var player: AudioPlayer
    var varispeed: VariSpeed
    private var varispeedAU: AVAudioUnitVarispeed
    var fader: Fader
    var fadeAutomationEvents: [AutomationEvent] = []
    var outputNode: Node {
        get { fader }
    }

    var playback: SamplePlayback?
    var playbackId: String? {
        get { self.playback?.playbackId }
    }
    var sampleId: String?

    var available: Bool {
        get { self.playback == nil }
    }

    var startTime: AVAudioTime?

    init() {
        self.player = AudioPlayer()
        self.varispeed = VariSpeed(player)
        self.varispeedAU = (self.varispeed.avAudioNode as! AVAudioUnitVarispeed)
        self.varispeedAU.bypass = true
        self.fader = Fader(self.varispeed, gain: 1.0)
        self.fader.stop()
        self.player.completionHandler = {
            // Check is in case this gets called asynchronously after new playback is scheduled
            if self.player.isPlaying { return }
            self.fader.stopAutomation()
            // we don't bypass the fader node because we'll get a click
            self.varispeedAU.bypass = true
            self.playback?.samplePlayer = nil
            self.playback = nil
        }
    }


    func schedulePlayback(
        sample: Sample,
        playbackId: String,
        atTime: AVAudioTime,
        volume: Double = 1.0,
        offset: Double = 0.0,
        playbackRate: Double = 1.0,
        fadeInDuration: Double = 0.0
    ) throws -> SamplePlayback {
        self.player.stop()
        self.playback?.samplePlayer = nil
        self.playback = nil
        self.fader.stopAutomation()
        self.fadeAutomationEvents = []

        do {
            try self.player.load(url: sample.url, buffered: false)
        } catch {
            print("Error: Cannot load sample: \(error.localizedDescription)")
            throw SamplePlaybackError.cannotLoadPlayer
        }

        self.startTime = atTime

        self.varispeedAU.bypass = (playbackRate == 1.0)
        self.varispeed.rate = Float(playbackRate)

        self.fader.gain = fadeInDuration > 0 ? 0 : Float(volume)
        self.fader.start()

        self.player.play(from: offset, to: nil, at: AVAudioTime(hostTime: atTime.hostTime), completionCallbackType: .dataPlayedBack)

        if fadeInDuration > 0 {
            self.fadeInAtStart(to: volume, duration: fadeInDuration)
        }

        self.playback = SamplePlayback(samplePlayer: self, sampleId: sample.id, playbackId: playbackId, duration: sample.duration - offset)

        return self.playback!
    }

    private func fadeInAtStart(to volume: Double, duration: Double) {
        self.fadeAutomationEvents.append(
            AutomationEvent(
                targetValue: Float(volume),
                startTime: 0, // TODO: or offset?
                rampDuration: Float(duration)
            )
        )
        self.fader.automateGain(events: self.fadeAutomationEvents, startTime: self.startTime)
    }

    func scheduleFade(at: AVAudioTime, to: Double, duration: Double) {
        let delay = at.timeIntervalSince(otherTime: self.startTime!) ?? 0

        // TODO: Fit curve of exponental function from Web Audio (Luke)

        self.fadeAutomationEvents.append(
            AutomationEvent(
                targetValue: Float(to),
                startTime: Float(delay),
                rampDuration: Float(duration)
            )
        )
        self.fader.automateGain(events: self.fadeAutomationEvents, startTime: self.startTime)
    }

    func changePlaybackRate(at: AVAudioTime, to: Double, duration: Double ) {
        let gap = at.timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + gap) {
            // TODO: (low priority) how to ramp playback rate?
            //self.varispeed.$rate.ramp(to: to, duration: duration)
        }
    }

    func scheduleStop(at: AVAudioTime?, fadeDuration maybeFadeDuration: Double?) {
        let fadeDuration = maybeFadeDuration ?? 0.05
        let secondsUntilDone = ((at ?? AVAudioTime.now()).timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0) + fadeDuration

        guard secondsUntilDone > -fadeDuration else {
            self.player.stop()
            self.player.completionHandler?()
            return
        }

        self.scheduleFade(at: at ?? AVAudioTime.now(), to: 0.0, duration: fadeDuration)

        let origPlaybackId = self.playbackId
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (secondsUntilDone + 0.01)) {
            guard origPlaybackId == self.playbackId else { return }  // make sure this player hasn't been reassigned
            self.player.stop()
            self.player.completionHandler?()
        }
    }
    
    func stopImmediately() {
        self.player.stop()
        self.player.completionHandler?()
    }
}


//TODO:- In order for Varispeed to ramp like gain we would have to not only extend the class in AudioKit but actually change the implementation in AudioKit Itself.
//extension VariSpeed {
//    public static let rateRange: ClosedRange<AUValue> = 0.25 ... 4.0
//    public static let rateDef = NodeParameterDef(
//        identifier: "variSpeedRate",
//        name: "VariSpeed Rate",
//        address: akGetParameterAddress("VariSpeed Rate"),
//        defaultValue: 1.0, range:
//            rateRange,
//        unit: .rate)
//    @Parameter(rateDef) public var rateChange: AUValue
//}



// private var speedRateTimer: Timer?

// private func playbackRateRamp(duration: TimeInterval? = 1.0, toRate: Float, completion: (()->Void)? = nil) {
//     speedRateTimer?.invalidate()

//     let increment = 0.1 / duration!
//     speedRateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { speedRate in
//         let newRate = self.varispeed.rate - Float(increment)
//         self.varispeed.rate = newRate
//         if newRate == toRate {
//             speedRate.invalidate()
//             self.speedRateTimer = nil
//             completion?()
//         }
//     }
// }
