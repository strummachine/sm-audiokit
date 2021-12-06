//
//  SampleStorage.swift
//  sm-audiokit
//
//  Created by Luke Abbott on 12/3/21.
//

import Foundation
import AVFoundation
import UIKit

class SampleStorage {
    static func storeSample(sampleId: String, audioData: Data) -> (Sample?, AudioPackageError?) {
        /// Write the MP3 file to disk; this is easier than putting into CoreAudioBuffer
        /// TODO:- may do if let here if we want to allow some failures to write, however
        /// letting the whole function return nil is probably what we want if we can't successfully write a file.
        let urlTuple = self.writeFileToDisk(with: audioData, and: sampleId)
        guard let url = urlTuple.0 else {
            if let error = urlTuple.1 {
                return (nil, error)
            }
            else {
                fatalError()
            }
        }
      
        /// Grab duration of file
        let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)

        return (Sample(id: sampleId, url: url, duration: duration), nil)
    }
  
    private static func writeFileToDisk(with mp3Data: Data,and name: String) -> (URL?, AudioPackageError?) {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(name).mp3")
            do {
                try mp3Data.write(to: fileURL, options: .atomic)
                return (fileURL, nil)
            } catch {
                return (nil, AudioPackageError.unableToStoreSampleToDisk(error: error))
            }
        } catch {
            return (nil, AudioPackageError.unableToRetrieveDocumentsDirectory(error: error))
        }
    }
}
