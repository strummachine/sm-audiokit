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

    // TODO: I recomend we divorce start time from the actual sample
//    var startTime: AVAudioTime
    
    var speedRateTimer: Timer?

    init?(
        sample: Sample,
        channel: Channel,
        playbackId: String,
        volume: Float = 1.0,
        offset: Float = 0.0,
        playbackRate: Float = 1.0,
        fadeInDuration: Float = 0.0
    ) {
          self.sampleId = sample.id
          self.duration = sample.duration - offset
          self.playbackId = playbackId
      
          // TODO: if AudioPlayer doesn't load, don't instantiate the class; throw an error, catch it up the stack
          player = AudioPlayer(url: sample.url, buffered: true)!
        
          // Apply time shift
          varispeed = VariSpeed(player)
          if playbackRate != 1.0 {
              varispeed.rate = playbackRate
          }
          
          fader = Fader(varispeed, gain: volume)
      
          channel.attach(player: player, outputNode: outputNode)
        
          
          // TODO: apply fadeInDuration, but NOT FOR v1 - I don't use fade-ins in production Strum Machine at this point, actually
            
          // The following code may or may not be a helpful start...
          //player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
        }

    func play(from offset: Float, at startTime: AVAudioTime) {
        // TODO: pass `offset` to `from` parameter
        let fromTimeInterval = TimeInterval(offset)
        player.play(from: fromTimeInterval, to: nil, at: startTime, completionCallbackType: .dataPlayedBack)
    }
    
    func play() {
        player.play()
    }
    
    func fade(at: Float, to: Float, duration: Float) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.offSetNow(with: at)) {
            self.fader.$leftGain.ramp(to: to, duration: duration)
            self.fader.$rightGain.ramp(to: to, duration: duration)
        }
    }
  
    func changePlaybackRate(at: Float, to: Float, duration: Float ) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.offSetNow(with: at)) {
          // TODO: (low priority) how to ramp playback rate?
          //self.varispeed.$rate.ramp(to: to, duration: duration)
            self.playbackRateRamp(duration: TimeInterval(duration), toRate: to) {
                print("Varispeed ramped to:\(self.varispeed.rate)")
            }
        }
    }

    func stop(at: Float? = 0.0) {
        // TODO: does AudioPlayer.stop() do a quick ramp-down to avoid clicks?
        // TODO:- It does not sadly we have to perform the fade
        if let atTime = at {
            // TODO: convert AVAudioTime to dispatch time
            let stopTime = DispatchTime.offSetNow(with: atTime)
            DispatchQueue.main.asyncAfter(deadline: stopTime) {
                self.player.stop()
            }
        }
        else {
            self.player.stop()
        }
    }
    
    private func playbackRateRamp(duration: TimeInterval? = 1.0,toRate: Float, completion: (()->Void)? = nil) {
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


