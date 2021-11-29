//
//  Sample.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//
import Foundation
import AudioKit
import AVFAudio

struct Sample {

    var id: String
    var defaultVolume: Double = 1

    var fileURL: URL
    var file: AVAudioFile
    var fileFormat: AVAudioFormat {
        get { file.processingFormat }
    }
    
    var fileSampleRate: Double {
        get { fileFormat.sampleRate }
    }
    var lengthInSamples: AVAudioFramePosition {
        get { file.length }
    }
    var lengthInSeconds: Double {
        get { Double(file.length) / fileFormat.sampleRate }
    }

    //// Failable initalizer, lets us pass a nil optional
    //// in case we can't load the file.
    init?(id: String, fileURL: URL, defaultVolume: Double = 1.0) {
        self.id = id
        self.fileURL = fileURL
        self.defaultVolume = defaultVolume
        
        do {
            self.file = try AVAudioFile(forReading: fileURL)
        } catch {
            print("Error: Cannot load sample:\(error.localizedDescription)")
            return nil
        }
    }

}

