//
//  AudioManager.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/25/21.
//

import Foundation
import AudioKit

enum SampleTypes: String {
    case guitar = "Guitar"
    case bass = "Bass"
    case drums = "Drums"
}

class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()
    
    let mainMixer: Mixer
    
    var sampleBank: [AudioPlayer] = []
    
    init() {
        mainMixer = Mixer(sampleBank, name: SampleTypes.guitar.rawValue)
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
