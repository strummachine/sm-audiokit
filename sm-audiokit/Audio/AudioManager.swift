//
//  AudioManager.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/25/21.
//

import Foundation
import AudioKit

class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()
    
    let mainMixer: Mixer
    
    var sampleManager: SampleManager
    
    init() {
        sampleManager = SampleManager()
        mainMixer = Mixer()
        sampleManager.getAllNodes().map({mainMixer.addInput($0.player)})
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
}
