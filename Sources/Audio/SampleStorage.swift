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
    static func storeSample(sampleId: String, packageId: String, audioData: Data) -> (Sample?, AudioPackageError?) {
        /// Write the MP3 file to disk; this is easier than putting into CoreAudioBuffer
        /// TODO:- may do if let here if we want to allow some failures to write, however
        /// letting the whole function return nil is probably what we want if we can't successfully write a file.
        
        let combinedFileName = String(sampleId+SpecialStringTypes.Pi.rawValue+packageId)
        let urlTuple = self.writeFileToDisk(with: audioData, and: combinedFileName)
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
    
    static public func getSampleList() throws -> [String] {
        ////1. Get the document directory url
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioManagerError.cannotUnwrapDocumentsDirectoryURL
        }

        do {
            ////2. Get the directory contents urls (including subfolder urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            print(directoryContents)

            ////3. Filter for the mp3 files
            let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            print("mp3 urls:",mp3Files)
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            print("mp3 list:", mp3FileNames)
            
            ////4. Replace Pi with Slash in filename
            let sampleList = mp3FileNames.map {$0.replacingOccurrences(of: SpecialStringTypes.Pi.rawValue, with: SpecialStringTypes.Slash.rawValue)}
            return sampleList
        } catch {
            throw error
        }
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
    
    public static func deleteSamples(with samplesToDelete:[String]) throws -> String? {
        ////1. Get the document directory url
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioManagerError.cannotUnwrapDocumentsDirectoryURL
        }

        do {
            ////2. Get the directory contents urls (including subfolder urls)
            let fileURLs = try FileManager.default.contentsOfDirectory(at:documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            ////3. Filter the files we need to delete.
            ///
            //FIXME: We probably need additional checks, or cut off the path etc..
            let filesToDelete = fileURLs.filter{!samplesToDelete.contains($0.absoluteString)}
            for fileURL in filesToDelete {
                if fileURL.pathExtension == "mp3"{
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
            return "Successfully deleted requested mp3 samples"
        } catch  {
            throw error
        }
    }
    
    //For debugging purposes
    public static func deleteAllFiles() throws -> String {
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioManagerError.cannotUnwrapDocumentsDirectoryURL
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at:documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "mp3" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
            return "Successfully deleted all mp3 samples"
        } catch  {
            throw error
        }
    }
}

enum SpecialStringTypes: String {
    case Pi = "π"
    case Slash = "/"
}
