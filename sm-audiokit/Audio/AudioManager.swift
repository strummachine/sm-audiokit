//
//  AudioManager.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/25/21.
//

import Foundation
import AudioKit
import AVFAudio

class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()
    
    let mainMixer: Mixer
    var audioPlayer: AudioPlayer = AudioPlayer()
    var sampleManager: SampleManager
    
    init() {
        sampleManager = SampleManager()
        mainMixer = Mixer(audioPlayer)
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
            audioPlayer.play()
        } catch {
            print("Error: can't load audio player:\(error.localizedDescription)")
        }
    }
    
}
