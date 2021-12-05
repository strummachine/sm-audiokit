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
        sampleManager.attachSamplePlayersToMixer(mixer: mainMixer)
        
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
    
    public func loadPlayer(with file: AVAudioFile, fadeDuration: Float, fadeStart: Int) {
        do {
            try audioPlayer.load(file: file)
            
            let duration: Int = Int(audioPlayer.duration*1000)
            let fadeDelay = duration - fadeStart
            print("Fade Delay:\(fadeDelay)")
            
            audioPlayer.completionHandler = {
                self.fader.gain = 4.0
                NotificationCenter.default.post(name: Notification.Name("PlayerCompletion"), object: nil)
            }
            audioPlayer.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(fadeDelay)) {
                self.fader.$leftGain.ramp(to: 0.0, duration: fadeDuration)
                self.fader.$rightGain.ramp(to: 0.0, duration: fadeDuration)
            }
        } catch {
            print("Error: can't load audio player:\(error.localizedDescription)")
        }
    }
    
}
