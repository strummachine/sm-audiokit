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
    var duration: Float
    var playbackId: String

    var startTime: AVAudioTime
    
    var speedRateTimer: Timer?

    init (
        sample: Sample,
        channel: Channel,
        playbackId: String,
        atTime: AVAudioTime,
        volume: Float = 1.0,
        offset: Float = 0.0,
        playbackRate: Float = 1.0,
        fadeInDuration: Float = 0.0
    ) throws {
        self.sampleId = sample.id
        self.duration = sample.duration - offset
        self.playbackId = playbackId
        self.startTime = atTime

        // TODO: if AudioPlayer doesn't load, don't instantiate the class; throw an error, catch it up the stack
        guard let tmpPlayer = AudioPlayer(url: sample.url, buffered: true) else {
            throw SamplePlaybackError.cannotLoadPlayer
        }
        
        self.player = tmpPlayer

        // Apply pitch shift
        self.varispeed = VariSpeed(player)
        if playbackRate != 1.0 {
          varispeed.rate = playbackRate
        }

        self.fader = Fader(varispeed, gain: volume)

        print("Channel:\(channel.id)")
        channel.attach(player: self.player, outputNode: self.outputNode)

        // TODO: pass `offset` to `from` parameter
        print(AudioManager.shared.mainMixer.connectionTreeDescription)
        print("Player:\(self.player.connectionTreeDescription) | \(self.player)")
        
        
        self.player.play(from: nil, to: nil, at: startTime, completionCallbackType: .dataPlayedBack)

        // TODO: apply fadeInDuration, but NOT FOR v1 - I don't use fade-ins in production Strum Machine at this point, actually
        // The following code may or may not be a helpful start...
        //player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
    }

    func fade(at: AVAudioTime, to: Float, duration: Float) {
        // TODO: Needs fixing
        let gap = Int(at.hostTime - self.player.avAudioNode.lastRenderTime!.hostTime)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .nanoseconds(gap))) {
            self.fader.$leftGain.ramp(to: to, duration: duration)
            self.fader.$rightGain.ramp(to: to, duration: duration)
        }
    }
  
    func changePlaybackRate(at: AVAudioTime, to: Float, duration: Float ) {
        let gap = Int(at.hostTime - self.player.avAudioNode.lastRenderTime!.hostTime)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .nanoseconds(gap))) {
          // TODO: (low priority) how to ramp playback rate?
          //self.varispeed.$rate.ramp(to: to, duration: duration)
        }
    }

    func stop(at: AVAudioTime?) {
        // TODO: does AudioPlayer.stop() do a quick ramp-down to avoid clicks?
        if (at == nil) {
            self.player.stop()
        } else {
            // TODO: convert AVAudioTime to dispatch time
            let stopTime = DispatchTime.now()
            DispatchQueue.main.asyncAfter(deadline: stopTime) {
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


