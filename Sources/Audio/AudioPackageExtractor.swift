//
//  AudioPackage.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import CoreAudio
import AudioToolbox
import AVFoundation

class AudioPackageExtractor {
    
    public static func extractAudioPackage(completion: @escaping (Result<[Sample],AudioPackageError>)-> Void) {
        ////1. Get path for audio-package file
        guard let pathForFile = Bundle.main.path(forResource: "testbed_mono_mp3", ofType: "audio-package") else {
            completion(.failure(AudioPackageError.unableToFindPathForResrouce))
            return
        }
      
        ////2. Convert file path to URL
        let url = URL(fileURLWithPath: pathForFile)
        
        ////3. Load contents of file into Data object
        let dataTuple = AudioPackageExtractor.loadDatafromURL(with: url)
        
        guard let data = dataTuple.0 else {
            if let error = dataTuple.1 {
                completion(.failure(error))
                return
            }
            else {
                ////3a. If we were unable to unwrap both the data and the error, something spectacularly wrong happened.
                ////Hard crash. We can remove this for production, but this should never happen.
                fatalError()
            }
        }
        
        ////4. Extract JSON Manifest as Tuple of the JSON string and byte-offset of first file
        let manifestResult = AudioPackageExtractor.extractJSONManifest(with: data.bytes)
        let manifestJSONData = manifestResult.0
        let firstFileByteOffset = manifestResult.1
        
        ////5. Decode JSON Manifest as AudioPackageManifest struct
        let packageManifestTuple = AudioPackageExtractor.decodeJSONManifest(with: manifestJSONData)
        
        guard let packageManifest = packageManifestTuple.0 else {
            if let error = packageManifestTuple.1 {
                completion(.failure(error))
                return
            }
            else {
                fatalError()
            }
        }

        ////6. Prep array of [Sample] for successfull read and return
        var results: [Sample] = []
        
        ////7. Loop through each sample to extract MP3 data from audio-package
        var nextFileByteOffset = firstFileByteOffset
        
        let group = DispatchGroup()
        for sampleDef in packageManifest.samples {
            group.enter()
            ////8. Calculate byte range for this file and slice byte array accordingly
            let byteRange = nextFileByteOffset..<(nextFileByteOffset+sampleDef.length)
            let bytesForAudioPacket: [UInt8] = Array(data.bytes[byteRange])
          
            ////9. Save audio data to disk and create Sample
            
            SampleStorage.storeSample(sampleId: sampleDef.name, packageId: Date().dateAndTimetoString(), audioData: Data(bytesForAudioPacket), completion: { result in
                switch result {
                case .success(let sample):
                    ////10. Add Sample to results
                    results.append(sample)
                  
                    ////11. Calculate byte offset for start of next file
                    nextFileByteOffset += sampleDef.length
                case .failure(let error):
                    group.leave()
                    completion(.failure(error))
                }
            })
            group.leave()
        }
        group.notify(queue: .main) {
            completion(.success(results))
        }
    }
    
    private static func iterateThroughManifest(with manifest:AudioPackageManifest,data: Data,and firstFileByteOffset: Int, completion: @escaping (Result<[Sample], AudioPackageError>)-> Void) {
        ////6. Prep array of [Sample] for successfull read and return
        var results: [Sample] = []
        
        ////7. Loop through each sample to extract MP3 data from audio-package
        var nextFileByteOffset = firstFileByteOffset
        
        for sampleDef in manifest.samples {
            ////8. Calculate byte range for this file and slice byte array accordingly
            let byteRange = nextFileByteOffset..<(nextFileByteOffset+sampleDef.length)
            let bytesForAudioPacket: [UInt8] = Array(data.bytes[byteRange])
          
            ////9. Save audio data to disk and create Sample
            
            SampleStorage.storeSample(sampleId: sampleDef.name, packageId: Date().dateAndTimetoString(), audioData: Data(bytesForAudioPacket), completion: { result in
                switch result {
                case .success(let sample):
                    ////10. Add Sample to results
                    results.append(sample)
                  
                    ////11. Calculate byte offset for start of next file
                    nextFileByteOffset += sampleDef.length
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    private static func loadDatafromURL(with url:URL) -> (Data?, AudioPackageError?) {
        do {
            let data = try Data(contentsOf: url)
            return (data, nil)
        } catch {
            return (nil, AudioPackageError.unableToLoadDataFromURL(error: error))
        }
    }
    
    private static func extractJSONManifest(with bytes:[UInt8]) -> (Data,Int) {
        let manifestLengthArray: [UInt8] = Array(bytes[..<4])
        
        let manifestLength = manifestLengthArray.reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        let firstFileByteOffset = Int(manifestLength) + 4
        
        let manifestJSON = bytes[4..<firstFileByteOffset]
        let manifestJSONString = "{\"samples\" : \(String(decoding: manifestJSON, as: UTF8.self))}"

        return (Data(manifestJSONString.utf8), firstFileByteOffset)
    }
    
    private static func decodeJSONManifest(with manifestData:Data) -> (AudioPackageManifest?, AudioPackageError?) {
        do {
            let packageManifest = try JSONDecoder().decode(AudioPackageManifest.self, from: manifestData)
            //print("AudioPackage Samples: \(packageManifest.samples)")
            return (packageManifest, nil)
        } catch {
            return (nil, AudioPackageError.unableToSerializeJSON(error: error))
        }
    }
    
    //// TODO:- May consider low level CoreAudio mp3 to buffer conversion if necessary
    //    private static func audioFileReaderWithData(audioData: Data) {
    //        var refAudioFileID: AudioFileID
    //        var inputFileID: ExtAudioFileRef
    //        var outputFileID: ExtAudioFileRef
    //
    //        var result: OSStatus = AudioFileOpenWithCallbacks(audioData, AudioFile_ReadProc.self, 0, AudioFile_GetSizeProc.self, 0, kAudioFileMP3Type, &refAudioFileID)
    //    }
}

struct AudioPackageManifest: Codable {
    let samples: [AudioPackageManifestSampleDefinition]
}

struct AudioPackageManifestSampleDefinition: Codable {
    let name: String
    let length: Int
}


extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    func subdata<R: RangeExpression>(in range: R) -> Self where R.Bound == Index {
        subdata(in: range.relative(to: self) )
    }
    func object<T>(at offset: Int) -> T {
        subdata(in: offset...).object()
    }
}

extension ContiguousBytes {
    func object<T>() -> T {
        withUnsafeBytes { $0.load(as: T.self) }
    }
}

extension Sequence where Element == UInt8  {
    var data: Data { .init(self) }
}

extension Collection where Element == UInt8, Index == Int {
    func object<T>(at offset: Int = 0) -> T {
        data.object(at: offset)
    }
}

extension Date {
    func toString(format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func dateAndTimetoString(format: String = "yyyy-MM-dd-HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
   
    func timeIn24HourFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}
