//
//  SampleStorage.swift
//  sm-audiokit
//
//  Created by Luke Abbott on 12/3/21.
//

import Foundation
import AVFoundation
import UIKit

let fileSeparator = "π"

struct PackageIdAndSampleId {
    let packageId: String
    let sampleId: String
}

struct StoredSample {
    let url: URL
    let sampleId: String
    let packageId: String
    let duration: Double? = nil
}

class SampleStorage {
    static var sampleBank: [String: Sample] = [:]

    static func storeSample(sampleId: String, packageId: String, audioData: Data, completion: @escaping (Result<Sample, SampleStorageError>) -> Void) {
        /// Write the MP3 file to disk; this is easier than putting into CoreAudioBuffer
        /// TODO:- may do if let here if we want to allow some failures to write, however
        /// letting the whole function return nil is probably what we want if we can't successfully write a file.
        
        /// Combine sampleId and packageId into the filename, they are sperated with unicode character
        DispatchQueue.global(qos: .utility).async {
            let combinedFileName = "\(packageId)\(fileSeparator)\(sampleId).mp3"
            
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
    
    static public func getStoredSampleList(completion: @escaping (Result<[StoredSample], SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            /// Get the document directory url
            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL)) }
                return
            }

            do {
                /// Get the directory contents urls (including subfolder urls)
                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

                /// Initial filtering for files with our special package-sample separator character
                let sampleURLs = directoryContents.filter({ $0.lastPathComponent.contains(fileSeparator) })

                var results: [StoredSample] = []

                for url in sampleURLs {
                    let filename = url.deletingPathExtension().lastPathComponent
                    let filenameComponents = filename.split(separator: Character(fileSeparator))
                    let packageId = String(filenameComponents[0])
                    let sampleId = String(filenameComponents[1] ?? "")
//                    let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
                    results.append(StoredSample(url: url, sampleId: sampleId, packageId: packageId))
                }

                DispatchQueue.main.async { completion(.success(results)) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotGetSampleList(error: error)))
                }
            }
        }
    }

    public static func loadSamplesFromDisk(_ packagesAndSamples:[PackageIdAndSampleId], completion: @escaping (Result<[Sample],SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            /// Get the document directory url
            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
            }
            do {
                /// Get the directory contents' urls
                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

                /// Initial filtering for files with our special package-sample separator character
                let sampleURLs = directoryContents.filter({ $0.lastPathComponent.contains(fileSeparator) })

                var samples: [Sample] = []

                for url in sampleURLs {
                    let filename = url.deletingPathExtension().lastPathComponent
                    let filenameComponents = filename.split(separator: Character(fileSeparator))
                    let packageId = String(filenameComponents[0])
                    let sampleId = String(filenameComponents[1] ?? "")
                    guard packagesAndSamples.contains(where: { ps in
                        ps.packageId == packageId && ps.sampleId == sampleId
                    }) else { continue }
                    let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
                    let sample = Sample(id: sampleId, url: url, duration: duration)
                    samples.append(sample)
                }

                DispatchQueue.main.async {
                    for sample in samples {
                        self.sampleBank[sample.id] = sample
                    }
                    completion(.success(samples))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotGetSampleList(error: error)))
                }
            }
        }
    }
    
    /// On success will return a string -- we can have this string give a list of the deleted files if necessary
    public static func deleteSamples(_ toDelete:[PackageIdAndSampleId], completion: @escaping (Result<String,SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            /// Get the document directory url
            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    completion(.failure(SampleStorageError.cannotUnwrapDocumentsDirectoryURL))
                }
                return
            }

            do {
                /// Get the directory contents urls (including subfolder urls)
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at:documentsUrl, 
                    includingPropertiesForKeys: nil, 
                    options: .skipsHiddenFiles
                )

                let filenamesToDelete = toDelete.map({ ps in
                    "\(ps.packageId)\(fileSeparator)\(ps.sampleId).mp3"
                })

                /// Filter the files we need to delete.
                ///
                //FIXME: We probably need additional checks, or cut off the path etc..
                let filesToDelete = fileURLs.filter{!filenamesToDelete.contains($0.absoluteString)}
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
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
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
