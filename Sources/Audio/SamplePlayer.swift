import Foundation
import AudioKit
import AVFoundation
import AudioKitEX
import CAudioKitEX

class SamplePlayer {
    var player: AudioPlayer
    var varispeed: VariSpeed
    var fader: Fader
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
        self.varispeed.stop()
        self.fader = Fader(self.varispeed, gain: 1.0)
        self.fader.stop()
        self.player.completionHandler = {
            self.fader.stopAutomation()
            self.fader.stop()
            self.varispeed.stop()
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
        self.playback?.samplePlayer = nil
        self.playback = nil

        if sample.id != self.sampleId {
            do {
                try self.player.load(url: sample.url)
            } catch {
                print("Error: Cannot load sample:\(error.localizedDescription)")
                throw SamplePlaybackError.cannotLoadPlayer
            }
            self.sampleId = sample.id
        }

        self.startTime = atTime

        self.varispeed.rate = Float(playbackRate)
        if playbackRate != 1.0 {
            self.varispeed.start()
        } else {
            self.varispeed.stop()
        }

        self.fader.stopAutomation()
        self.fader.gain = fadeInDuration > 0 ? 0 : Float(volume)
        self.fader.start()

        self.player.play(from: offset, to: nil, at: AVAudioTime(hostTime: atTime.hostTime), completionCallbackType: .dataPlayedBack)

        if fadeInDuration > 0 {
            self.fader.automateGain(events: [
                AutomationEvent(
                    targetValue: Float(volume),
                    startTime: 0, // TODO: or offset?
                    rampDuration: Float(fadeInDuration)
                )
            ], startTime: self.startTime)
        }

        self.playback = SamplePlayback(samplePlayer: self, sampleId: sample.id, playbackId: playbackId, duration: sample.duration - offset)

        return self.playback!
    }

    func fade(at: AVAudioTime, to: Double, duration: Double) {
        let delay = at.timeIntervalSince(otherTime: self.startTime!) ?? 0

        // TODO: Fit curve of exponental function from Web Audio (Luke)

        self.fader.automateGain(events: [
            AutomationEvent(
                targetValue: Float(to),
                startTime: Float(delay),
                rampDuration: Float(duration)
            )
        ], startTime: self.startTime)

        let origPlaybackId = self.playbackId
        if (to == 0.0) {
            if let lastRenderTime = self.player.avAudioNode.lastRenderTime {
                let delayFromNow = at.timeIntervalSince(otherTime: lastRenderTime) ?? 0
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (delayFromNow + duration + 0.3)) {
                    if origPlaybackId == self.playbackId {
                        self.player.stop()
                        self.player.completionHandler?()
                    }
                }
            }
        }
    }

    func changePlaybackRate(at: AVAudioTime, to: Double, duration: Double ) {
        let gap = at.timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + gap) {
            // TODO: (low priority) how to ramp playback rate?
            //self.varispeed.$rate.ramp(to: to, duration: duration)
        }
    }

    func stop(at: AVAudioTime?) {
        let gap = at?.timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + gap) {
            self.fader.$leftGain.ramp(to: 0.0, duration: 0.05)
            self.fader.$rightGain.ramp(to: 0.0, duration: 0.05)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05 + 0.02) {
                self.player.stop()
                self.player.completionHandler?()
            }
        }
    }
    
    func stop() {
        self.fader.$leftGain.ramp(to: 0.0, duration: 0.05)
        self.fader.$rightGain.ramp(to: 0.0, duration: 0.05)
        self.player.stop()
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
