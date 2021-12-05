//
//  SampleStorage.swift
//  sm-audiokit
//
//  Created by Luke Abbott on 12/3/21.
//

import Foundation
import AVFoundation

class SampleStorage {
    static func storeSample(sampleId: String, audioData: Data) -> Sample {
        /// Write the MP3 file to disk; this is easier than putting into CoreAudioBuffer
        /// TODO:- may do if let here if we want to allow some failures to write, however
        /// letting the whole function return nil is probably what we want if we can't successfully write a file.
        guard let url = self.writeFileToDisk(with: audioData, and: sampleId) else {
            fatalError("Error: Cannot write file to disk")
        }
      
        /// Grab duration of file
        let duration = Float(CMTimeGetSeconds(AVURLAsset(url: url).duration))

        return Sample(id: sampleId, url: url, duration: duration)
    }
  
    private static func writeFileToDisk(with mp3Data: Data,and name: String) -> URL? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(name).mp3")
        do {
            try mp3Data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("ERROR: cannot write mp3 - \(error)")
            return nil
        }
    }
}
