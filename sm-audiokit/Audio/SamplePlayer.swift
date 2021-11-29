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

    func play(sample: Sample, channel: String,playbackId: String, at atTime: Float, volume: Float?, offset: Float?, playbackRate: Float?, pitchShift: Float?, fadeInDuration: Double = 0) {
        self.sampleId = sample.id
        self.playbackId = playbackId
        do {
            try player.load(file: sample.file)
        } catch {
            print("Error: Cannot load sample:\(error)")
        }

        player.volume = volume ?? sample.defaultVolume
        timePitch.rate = playbackRate ?? 1.0
        timePitch.pitch = pitchShift ?? 0.0
        
//        player.fade.inTime = fadeInDuration == 0 ? 0.001 : fadeInDuration
//        player.play(at: timeToPlay)
//        startTime = timeToPlay
//        queuedTime = mach_absolute_time()

    }
    
    func fadeOut(fadeDuration: TimeInterval? = 1.0, completion: (()->Void)? = nil) {
        guard let fadeDuration = fadeDuration else {
            return
        }
        fadeTimer?.invalidate()
        let increment: Float = Float(0.1 / fadeDuration)
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { fadeOut in
            let newVolume = self.player.volume - increment
            if newVolume > 0.0 {
                self.player.volume = newVolume
            }
            else {
                self.player.volume = 0.0
                fadeOut.invalidate()
                self.fadeTimer = nil
                completion?()
            }
        }
    }
    
    func fadeIn(fadeDuration: TimeInterval? = 1.0, completion: (()->Void)? = nil) {
        guard let fadeDuration = fadeDuration else {
            return
        }
        fadeTimer?.invalidate()
        let increment: Float = Float(0.1 / fadeDuration)
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { fadeIn in
            let newVolume = self.player.volume + increment
            if newVolume < 1.0 {
                self.player.volume = newVolume
            }
            else {
                self.player.volume = 1.0
                fadeIn.invalidate()
                self.fadeTimer = nil
                completion?()
            }
        }
    }
    
    func pause() {
        fadeOut(fadeDuration: 0.5) {
            self.player.pause()
        }
    }


}


