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
    static var sampleBank: [String: Sample] = [:]

    static func storeSample(sampleId: String, packageId: String, audioData: Data, completion: @escaping (Result<Sample, SampleStorageError>) -> Void) {
        /// Write the MP3 file to disk; this is easier than putting into CoreAudioBuffer
        /// TODO:- may do if let here if we want to allow some failures to write, however
        /// letting the whole function return nil is probably what we want if we can't successfully write a file.
        
        /// Combine sampleId and packageId into the filename, they are sperated with unicode character
        DispatchQueue.global(qos: .utility).async {
            let combinedFileName = String(packageId+SpecialStringTypes.Pi.rawValue+sampleId)
            
            writeFileToDisk(data: audioData, fileName: combinedFileName, completion: { result in
                switch result {
                    case .success(let url):
                        let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
                        let sample = Sample(id: sampleId, url: url, duration: duration)
                        DispatchQueue.main.async {
                            self.sampleBank[sample.id] = sample
                            completion(.success(sample))
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                }
            })
        }
    }
    
    static public func getStoredSampleList(completion: @escaping (Result<[String], SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            /// Get the document directory url
            guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
            }

            do {
                /// Get the directory contents urls (including subfolder urls)
                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

                /// Filter for the mp3 files
                let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
                
                /// Delete mp3 extension
                let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
                
                /// Replace Pi with Slash in filename
                let sampleList = mp3FileNames.map {$0.replacingOccurrences(of: SpecialStringTypes.Pi.rawValue, with: SpecialStringTypes.Slash.rawValue)}

                DispatchQueue.main.async {
                    completion(.success(sampleList))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotGetSampleList(error: error)))
                }
            }
        }
    }
    
    public static func loadSamplesFromDisk(_ samplesToLoad:[String], completion: @escaping (Result<[Sample],SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            ////1. Get the document directory url
            guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
            }
            do {
                ////2. Get the directory contents urls (including subfolder urls)
                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

                ////3. Filter for the samples we need to load
                let sampleURLs = directoryContents.filter{ !samplesToLoad.contains($0.absoluteString) }
                let sampleStrings = sampleURLs.map({$0.absoluteString})
                ////4. Get the Sample Ids we need for the sampleBank
                let sampleIds = sampleStrings.map({$0.components(separatedBy: SpecialStringTypes.Pi.rawValue).first!})
                ////5. Get the sample Durations
                let sampleDurations = sampleURLs.map({CMTimeGetSeconds(AVURLAsset(url:$0).duration)})
                var samples: [Sample] = []
                ////6. Create sample structrs
                for (index,url) in sampleURLs.enumerated() {
                    let id = sampleStrings[index]
                    let duration = sampleDurations[index]
                    let sample = Sample(id: id, url: url, duration: duration)
                    samples.append(sample)
                }

                DispatchQueue.main.async {
                    completion(.success(samples))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotGetSampleList(error: error)))
                }
            }
            
        }
    }
    
    ////On success will return a string -- we can have this string give a list of the deleted files if necessary
    public static func deleteSamples(_ samplesToDelete:[String], completion: @escaping (Result<String,SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            ////1. Get the document directory url
            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
            }

            do {
                ////2. Get the directory contents urls (including subfolder urls)
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at:documentsUrl, 
                    includingPropertiesForKeys: nil, 
                    options: .skipsHiddenFiles
                )

                ////3. Filter the files we need to delete.
                ///
                //FIXME: We probably need additional checks, or cut off the path etc..
                let filesToDelete = fileURLs.filter{!samplesToDelete.contains($0.absoluteString)}
                for fileURL in filesToDelete {
                    ////4. We probably don't need this check but it is good practice.
                    if fileURL.pathExtension == "mp3"{
                        try FileManager.default.removeItem(at: fileURL)
                    }
                }
                DispatchQueue.main.async {
                    completion(.success(SampleLoadingMessageTypes.successDeleteList.rawValue))
                }
            } catch  {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotDeleteSamples(error: error)))
                }
            }
        }
    }
    
    //For debugging purposes
    public static func deleteAllStoredSamples(completion: @escaping (Result<String,SampleStorageError>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
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
                DispatchQueue.main.async {
                    completion(.success(SampleLoadingMessageTypes.successDeleteAll.rawValue))
                }
            } catch  {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotDeleteSamples(error: error)))
                }
            }
        }
    }
    
    private static func writeFileToDisk(data: Data, fileName: String, completion: @escaping (Result<URL, SampleStorageError>) -> Void) {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(fileName).mp3")
            do {
                try data.write(to: fileURL)
                completion(.success(fileURL))
            } catch {
                completion(.failure(SampleStorageError.unableToStoreSampleToDisk(error: error)))
            }
        } catch {
            completion(.failure(SampleStorageError.unableToRetrieveDocumentsDirectory(error: error)))
        }
    }
}

enum SampleLoadingMessageTypes: String {
    case successDeleteAll = "Successfully deleted all mp3 samples from documents directory"
    case successDeleteList = "Successfully deleted requested mp3 samples"
}

enum SpecialStringTypes: String {
    case Pi = "π"
    case Slash = "/"
}
