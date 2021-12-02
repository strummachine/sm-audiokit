//
//  SamplePlayer.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation
import AudioKitEX

class SamplePlayer {
    var player = AudioPlayer()
    var timePitch: TimePitch
    var fader: Fader
    var outputNode: Node {
        get { fader }
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
        fader = Fader(timePitch, gain: 1.0)
        player.completionHandler = {
            self.player.stop()
            self.sampleId = nil
            self.playbackId = nil
            self.fader.gain = 1.0
        }
    }
    
//    args.channel, // string
//    args.sampleId, // string (file to play)
//    args.atTime, // number
//    args.volume || DEFAULT_VOLUME, // number (scale TBD)
//    args.offset || 0, // number, start offset within file
//    args.playbackRate || (args.pitchShift ? 1.059463 ** args.pitchShift : 1), // number (playback rate)
//    args.fadeInDuration || 0,

    //TODO:- Make special return object status of calling these methods, duration, success etc...
    
    func load(sample: Sample, channel: String,playbackId: String, at atTime: Float, volume: Float? = 1.0, offset: Float? = 0.0, playbackRate: Float? = 1.0, pitchShift: Float? = 0.0, fadeInDuration: Double? = 0.0) {
        self.sampleId = sample.id
        self.playbackId = playbackId
        do {
            guard let buffer = try AVAudioPCMBuffer(file: sample.file) else {
                print("Error: Cannot load buffer")
                return
            }
            player.load(buffer: buffer)
        } catch {
            print("Error: Cannot load sample:\(error.localizedDescription)")
        }

        fader.gain = volume ?? sample.defaultVolume
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
    
    func play(with fadeDuration: Float? = 0.5) {
        player.play()
    }
    
    func fadeOut(with duration:Float) {
        fader.$leftGain.ramp(to: 0.0, duration: duration)
        fader.$rightGain.ramp(to: 0.0, duration: duration)
    }
    
    func fadeIn(with duration:Float) {
        fader.$leftGain.ramp(to: 1.0, duration: duration)
        fader.$leftGain.ramp(to: 1.0, duration: duration)
    }
}


