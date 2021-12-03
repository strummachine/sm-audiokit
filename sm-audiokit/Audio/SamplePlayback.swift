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
    var varispeed: VariSpeed  // not TimePitch as we want to adjust playback rate and pitch together
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

    // TODO: no idea if these are the right types...
    var startTime: AVAudioTime?
    var queuedTime: UInt64?
    
    var fadeTimer: Timer?

    // TODO: "channel" should probably be the Channel class instance
    init?(
        sample: Sample,
        channel: Channel,
        playbackId: String,
        atTime: AVAudioTime,
        volume: Float = 1.0,
        offset: Float = 0.0,
        playbackRate: Float = 1.0,
        fadeInDuration: Float = 0.0
    ) {
          self.sampleId = sample.id
          self.duration = sample.duration - offset
          self.playbackId = playbackId
      
          // TODO: if AudioPlayer doesn't load, don't instantiate the class; throw an error, catch it up the stack
          player = AudioPlayer(url: sample.url, buffered: true) as! AudioPlayer
        
          // Apply pitch shift
          varispeed = VariSpeed(player)
          if playbackRate != 1.0 {
              varispeed.rate = playbackRate
          }
          
          fader = Fader(varispeed, gain: volume)
      
          channel.attach(player: player, outputNode: outputNode)
        
          // TODO: pass `offset` to from parameter
          player.play(from: nil, to: nil, at: startTime, completionCallbackType: .dataPlayedBack)
          
          // TODO: apply fadeInDuration, but NOT FOR v1 - I don't use fade-ins in production Strum Machine at this point, actually
          // The following code may or may not be a helpful start...
          //player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
        
          self.startTime = atTime
        }

    func fade(at: AVAudioTime, to: Float, duration: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.fader.$leftGain.ramp(to: to, duration: duration)
            self.fader.$rightGain.ramp(to: to, duration: duration)
        }
    }
  
    func changePlaybackRate(at: AVAudioTime, to: Float, duration: Float ) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
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
}


