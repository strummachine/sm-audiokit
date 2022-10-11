import Foundation
import AudioKit
import AVFoundation
import AudioKitEX
import CAudioKitEX

final class SamplePlayer {
    static private var queue = DispatchQueue(label: "com.strummachine.mobileapp.SamplePlayerDispatchQueue", qos: .default)

    public private(set) var pool: SamplePlayerPool
    public private(set) var player = BasicAudioPlayer()

    public private(set) var fader: MonoFader
    public private(set) var fadeAutomationEvents: [AutomationEvent] = []

    public private(set) var playbackId: String?
    public private(set) var playbackStartTime: AVAudioTime?

    public var outputNode: Node {
        get { fader }
    }

    public init(pool: SamplePlayerPool) {
        self.pool = pool
        self.fader = MonoFader(self.player, gain: 1.0)
        self.fader.bypass()
        self.player.completionHandler = {
            SamplePlayer.queue.async {
                self.fader.stopAutomation()  // not stopping Fader; causes popping
                self.pool.returnPlayer(self)
            }
        }
    }

    func reset() {
        playbackId = nil
        playbackStartTime = nil
    }

    func schedulePlayback(
        sample: Sample,
        playbackId: String,
        atTime: AVAudioTime,
        volume: Double = 1.0,
        offset: Double = 0.0,
        fadeInDuration: Double = 0.0
    ) throws {
        self.playbackId = playbackId
        self.playbackStartTime = AVAudioTime(hostTime: atTime.hostTime)

        var buffer: AVAudioPCMBuffer?
        do {
            buffer = try sample.getBuffer(forPlayer: self.player.playerNode)
        } catch {
            print("Error: Cannot load sample: \(error.localizedDescription)")
            throw SamplePlaybackError.cannotLoadPlayer
        }

        SamplePlayer.queue.async {
            self.player.stop()
            self.player.buffer = buffer
            self.fader.stopAutomation()
            self.fadeAutomationEvents = []

            guard let scheduleTime = self.playbackStartTime else {
                return
            }

            self.fader.gain = fadeInDuration > 0 ? 0 : Float(volume)
            self.fader.start()

            self.player.play(from: offset, to: nil, at: scheduleTime, completionCallbackType: .dataPlayedBack)

            if fadeInDuration > 0 {
                self.setFade(at: scheduleTime, to: volume, duration: fadeInDuration)
            }
        }
    }

    /// This should only be called when already in the proper thread
    private func setFade(at startTime: AVAudioTime, to volume: Double, duration: Double) {
        guard let scheduleTime = self.playbackStartTime else {
            print("Tried to set fade for player with no playbackStartTime")
            return
        }
        let delay = startTime.timeIntervalSince(otherTime: scheduleTime)!
        // TODO: Fit curve of exponental function from Web Audio?
        self.fadeAutomationEvents.append(
            AutomationEvent(
                targetValue: Float(volume),
                startTime: Float(delay), // TODO: or offset?
                rampDuration: Float(duration)
            )
        )
        self.fader.automateGain(events: self.fadeAutomationEvents, startTime: scheduleTime)
    }

    func scheduleFade(at: AVAudioTime, to: Double, duration: Double) {
        SamplePlayer.queue.async {
            self.setFade(at: at, to: to, duration: duration)
        }
    }

    func scheduleStop(at: AVAudioTime?, fadeDuration maybeFadeDuration: Double?) {
        SamplePlayer.queue.async {
            let fadeDuration = maybeFadeDuration ?? 0.05
            let secondsUntilDone = ((at ?? AVAudioTime.now()).timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0) + fadeDuration

            guard secondsUntilDone > -fadeDuration else {
                self.player.stop()
                self.player.completionHandler?()
                return
            }

            self.setFade(at: at ?? AVAudioTime.now(), to: 0.0, duration: fadeDuration)

            let origPlaybackId = self.playbackId
            SamplePlayer.queue.asyncAfter(deadline: DispatchTime.now() + (secondsUntilDone + 0.01)) {
                guard origPlaybackId == self.playbackId else { return }  // make sure this player hasn't been reassigned
                self.player.stop()
                self.player.completionHandler?()
            }
        }
    }

    func stopImmediately() {
        SamplePlayer.queue.async {
            self.player.stop()
            self.fader.stopAutomation()  // not stopping Fader; causes popping
            self.pool.returnPlayer(self)
        }
    }

}
