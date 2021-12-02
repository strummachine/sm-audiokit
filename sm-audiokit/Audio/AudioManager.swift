//
//  AudioManager.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/25/21.
//

import Foundation
import AudioKit
import AVFAudio
import AudioKitEX

class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()
    
    let mainMixer: Mixer
    var audioPlayer: AudioPlayer = AudioPlayer()
    var fader: Fader
    var sampleManager: SampleManager
    
    init() {
        sampleManager = SampleManager()
        fader = Fader(audioPlayer, gain: 1.0)
        mainMixer = Mixer(fader)
        //sampleManager.getAllNodes().map({mainMixer.addInput($0.player)})
        
        engine.output = mainMixer
    }
    
    public func start() {
        do {
            try engine.start()
        } catch {
            print("Error: Cannot start audio engine: \(error.localizedDescription)")
        }
    }
    public func stop() {
        engine.stop()
    }
    
    public func loadPlayer(with file: AVAudioFile) {
        do {
            try audioPlayer.load(file: file)
            let duration = audioPlayer.duration
            print("Duration:\(duration)")
            audioPlayer.completionHandler = {
                self.fader.gain = 4.0
            }
            audioPlayer.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
                self.fader.$leftGain.ramp(to: 0.0, duration: 0.50)
                self.fader.$rightGain.ramp(to: 0.0, duration: 0.50)
            }
        } catch {
            print("Error: can't load audio player:\(error.localizedDescription)")
        }
    }
    
}
