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

    static func storeSample(packageIdAndSampleId: PackageIdAndSampleId, audioData: Data, completion: @escaping (Result<Sample, SampleStorageError>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let sampleURL = try getSampleURL(packageAndSample: packageIdAndSampleId)

                do {
                    try audioData.write(to: sampleURL, options: .atomic)
                    let duration = CMTimeGetSeconds(AVURLAsset(url: sampleURL).duration)
                    let sample = Sample(id: packageIdAndSampleId.sampleId, url: sampleURL, duration: duration)
                    DispatchQueue.main.async {
                        self.sampleBank[sample.id] = sample
                        completion(.success(sample))
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(SampleStorageError.unableToStoreSampleToDisk(error: error))) }
                }

            } catch {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.unableToRetrieveDocumentsDirectory(error: error))) }
            }
        }
    }
    
    static public func getStoredSampleList(completion: @escaping (Result<[StoredSample], SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let results = try self.getStoredSamples()

                print("Storage directory URL:")
                print((try? self.getStorageDirectoryURL())?.absoluteString ?? "UNKNOWN")

                DispatchQueue.main.async { completion(.success(results)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.cannotGetSampleList(error: error))) }
            }
        }
    }

    public static func loadSamplesFromDisk(_ packagesAndSamples:[PackageIdAndSampleId], completion: @escaping (Result<[Sample],SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let storedSamples = try self.getStoredSamples()

                var samples: [Sample] = []
                for stored in storedSamples {
                    guard packagesAndSamples.contains(where: { desired in
                        desired.packageId == stored.packageId && desired.sampleId == stored.sampleId
                    }) else { continue }
                    let duration = CMTimeGetSeconds(AVURLAsset(url: stored.url).duration)
                    let sample = Sample(id: stored.sampleId, url: stored.url, duration: duration)
                    samples.append(sample)
                }

                DispatchQueue.main.async {
                    for sample in samples {
                        self.sampleBank[sample.id] = sample
                    }
                    completion(.success(samples))
                }

            } catch {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.cannotGetSampleList(error: error))) }
            }
        }
    }
    
    public static func deleteSamples(_ toDelete:[PackageIdAndSampleId], completion: @escaping (Result<String,SampleStorageError>)-> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let sampleURLs = try self.getStoredSampleURLs()

                let filenamesToDelete = toDelete.map({ ps in
                    self.makeFileName(packageAndSample: ps)
                })

                let filesToDelete = sampleURLs.filter({ filenamesToDelete.contains($0.lastPathComponent) })
                for fileURL in filesToDelete {
                    try FileManager.default.removeItem(at: fileURL)
                }

                DispatchQueue.main.async {
                    completion(.success(SampleLoadingMessageTypes.successDeleteList.rawValue))
                }

            } catch  {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.cannotDeleteSamples(error: error))) }
            }
        }
    }
    
    //For debugging purposes
    public static func deleteAllStoredSamples(completion: @escaping (Result<String,SampleStorageError>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let sampleURLs = try self.getStoredSampleURLs()
                
                for fileURL in sampleURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }

                DispatchQueue.main.async {
                    completion(.success(SampleLoadingMessageTypes.successDeleteAll.rawValue))
                }

            } catch  {
                DispatchQueue.main.async { completion(.failure(SampleStorageError.cannotDeleteSamples(error: error))) }
            }
        }
    }
    
    private static func makeFileName(packageAndSample: PackageIdAndSampleId) -> String {
        "\(packageAndSample.packageId)\(fileSeparator)\(packageAndSample.sampleId).mp3"
    }

    private static func getSampleURL(packageAndSample: PackageIdAndSampleId) throws -> URL {
        return try self.getStorageDirectoryURL().appendingPathComponent(makeFileName(packageAndSample: packageAndSample))
    }

    private static func getStorageDirectoryURL() throws -> URL {
        // could also be .applicationSupportDirectory
        let cachesDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let samplesDir = cachesDir.appendingPathComponent(Bundle.main.bundleIdentifier ?? "app").appendingPathComponent("samples")
        try FileManager.default.createDirectory(at: samplesDir, withIntermediateDirectories: true, attributes: nil)
        return samplesDir
    }

    private static func getStoredSampleURLs() throws -> [URL] {
        let storageDirectory = try self.getStorageDirectoryURL()
        let directoryContents = try FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])

        /// Initial filtering for files with our special package-sample separator character
        let sampleURLs = directoryContents.filter({ $0.lastPathComponent.contains(fileSeparator) })
        return sampleURLs
    }

    private static func getStoredSamples() throws -> [StoredSample] {
        let sampleURLs = try self.getStoredSampleURLs()

        var results: [StoredSample] = []

        for url in sampleURLs {
            let filename = url.deletingPathExtension().lastPathComponent
            let filenameComponents = filename.split(separator: Character(fileSeparator))
            if filenameComponents.count < 2 { continue }
            let packageId = String(filenameComponents[0])
            let sampleId = String(filenameComponents[1])
            // let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            results.append(StoredSample(url: url, sampleId: sampleId, packageId: packageId))
        }

        return results
    }
}

enum SampleLoadingMessageTypes: String {
    case successDeleteAll = "Successfully deleted all mp3 samples from documents directory"
    case successDeleteList = "Successfully deleted requested mp3 samples"
}
