//
//  SamplePlayer.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation

class SamplePlayer {
    var player = AudioPlayer()
    var timePitch: TimePitch
    var outputNode: Node {
        get { timePitch }
    }
    var isPlaying: Bool {
        get { player.isPlaying }
    }
    var sampleId: String?
    var playbackId: String?

    var startTime: AVAudioTime?
    var queuedTime: UInt64?
    
    var fadeTimer: Timer?

    init() {
        timePitch = TimePitch(player)

        player.completionHandler = {
          self.player.stop()
          self.sampleId = nil
//          self.playbackId = nil
        }
    }
    
//    args.channel, // string
//    args.sampleId, // string (file to play)
//    args.atTime, // number
//    args.volume || DEFAULT_VOLUME, // number (scale TBD)
//    args.offset || 0, // number, start offset within file
//    args.playbackRate || (args.pitchShift ? 1.059463 ** args.pitchShift : 1), // number (playback rate)
//    args.fadeInDuration || 0,

    func load(sample: Sample, channel: String,playbackId: String, at atTime: Float, volume: Float?, offset: Float?, playbackRate: Float?, pitchShift: Float?, fadeInDuration: Double = 0) {
        self.sampleId = sample.id
        self.playbackId = playbackId
        do {
            guard let buffer = try AVAudioPCMBuffer(file: sample.file) else {
                print("Error: Cannot load buffer")
                return
            }
            //TODO:- We will make a new buffer with appropriate fadeIn and then load player
            //buffer?.smFadeIn(inTime: <#T##Double#>)
            player.load(buffer: buffer)
        } catch {
            print("Error: Cannot load sample:\(error.localizedDescription)")
        }

        player.volume = volume ?? sample.defaultVolume
        timePitch.rate = playbackRate ?? 1.0
        timePitch.pitch = pitchShift ?? 0.0
        
        let outputFormat = player.avAudioNode.outputFormat(forBus: 0)
        let delayTime = 0.0
        let now = player.avAudioNode.lastRenderTime?.sampleTime
        
        
//        let scheduledTime = AVAudioTime(hostTime: <#T##UInt64#>)
//        player.schedule(at: atTime, completionCallbackType: .dataPlayedBack)
        
//        player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
//        player.play(at: timeToPlay)
//        startTime = timeToPlay
//        queuedTime = mach_absolute_time()

    }
    
    func play(startTime: AVAudioTime) {
        player.play(from: nil, to: nil, at: startTime, completionCallbackType: .dataPlayedBack)
    }
    
    //TODO:- Need scheduled fades at scheduled playback (even fades can be scheduled themeselves)
    
//    func pause() {
//        fadeOut(fadeDuration: 0.5) {
//            self.player.pause()
//        }
//    }


}


