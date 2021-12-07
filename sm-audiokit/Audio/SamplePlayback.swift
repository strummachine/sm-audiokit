//
//  SamplePlayback.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation
import AudioKitEX

class SamplePlayback {
    var player: AudioPlayer
    var varispeed: VariSpeed  // not TimePitch as we want to adjust playback rate and pitch together by adjusting sample rate
    var fader: Fader
    var outputNode: Node {
        get { fader }
    }
    var isPlaying: Bool {
        get { player.isPlaying }
    }
    var sampleId: String
    var duration: Double
    var playbackId: String

    var startTime: AVAudioTime
    
    var speedRateTimer: Timer?

    init (
        sample: Sample,
        channel: Channel,
        playbackId: String,
        atTime: AVAudioTime,
        volume: Double = 1.0,
        offset: Double = 0.0,
        playbackRate: Double = 1.0,
        fadeInDuration: Double = 0.0
    ) throws {
        self.sampleId = sample.id
        self.duration = sample.duration - offset
        self.playbackId = playbackId
        self.startTime = atTime

        guard let tmpPlayer = AudioPlayer(url: sample.url, buffered: true) else {
            throw SamplePlaybackError.cannotLoadPlayer
        }
        
        self.player = tmpPlayer

        // Apply pitch shift
        self.varispeed = VariSpeed(player)
        if playbackRate != 1.0 {
          varispeed.rate = Float(playbackRate)
        }

        self.fader = Fader(varispeed, gain: Float(volume))

        channel.attach(outputNode: self.outputNode)

        self.player.completionHandler = {
            channel.detach(outputNode: self.outputNode)
        }

        // TODO: pass `offset` to `from` parameter
        self.player.play(from: offset, to: nil, at: AVAudioTime(hostTime: startTime.hostTime), completionCallbackType: .dataPlayedBack)

        // TODO: apply fadeInDuration, but NOT FOR v1 - I don't use fade-ins in production Strum Machine at this point, actually
        // The following code may or may not be a helpful start...
        //player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
    }

    func fade(at: AVAudioTime, to: Double, duration: Double) {
        let gap = at.timeIntervalSince(otherTime: AVAudioTime.now()) ?? 0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + gap) {
            self.fader.$leftGain.ramp(to: Float(to), duration: Float(duration))
            self.fader.$rightGain.ramp(to: Float(to), duration: Float(duration))
            if (to == 0.0) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                    self.player.stop()
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
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.07) {
                self.player.stop()
            }
        }
    }
    
    private func playbackRateRamp(duration: TimeInterval? = 1.0, toRate: Float, completion: (()->Void)? = nil) {
        speedRateTimer?.invalidate()
        
        let increment = 0.1 / duration!
        speedRateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { speedRate in
            let newRate = self.varispeed.rate - Float(increment)
            self.varispeed.rate = newRate
            if newRate == toRate {
                speedRate.invalidate()
                self.speedRateTimer = nil
                completion?()
            }
        }
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


