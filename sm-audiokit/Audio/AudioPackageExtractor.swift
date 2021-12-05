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
    
    public static func extractAudioPackage() -> [Sample]? {
        ////1. Get path for audio-package file
        guard let pathForFile = Bundle.main.path(forResource: "testbed_mp3", ofType: "audio-package") else {
            fatalError("Can't open audio-package")
        }
      
        ////2. Convert file path to URL
        let url = URL(fileURLWithPath: pathForFile)
        
        ////3. Load contents of file into Data object
        guard let data = AudioPackageExtractor.loadDatafromURL(with: url) else {
            print("Error: Cannot load data from url")
            return nil
        }

        ////4. Extract JSON Manifest as Tuple of the JSON string and byte-offset of first file
        let manifestResult = AudioPackageExtractor.extractJSONManifest(with: data.bytes)
        let manifestJSONData = manifestResult.0
        let firstFileByteOffset = manifestResult.1
        
        ////5. Decode JSON Manifest as AudioPackageManifest struct
        guard let packageManifest = AudioPackageExtractor.decodeJSONManifest(with: manifestJSONData) else {
            return nil
        }

        ////6. Prep array of [Sample] for successfull read and return
        var results: [Sample] = []
        
        ////7. Loop through each sample to extract MP3 data from audio-package
        var nextFileByteOffset = firstFileByteOffset
        for sampleDef in packageManifest.samples {
            ////8. Calculate byte range for this file and slice byte array accordingly
            let byteRange = nextFileByteOffset..<(nextFileByteOffset+sampleDef.length)
            let bytesForAudioPacket: [UInt8] = Array(data.bytes[byteRange])
          
            ////9. Save audio data to disk and create Sample
            let sample = SampleStorage.storeSample(sampleId: sampleDef.name, audioData: Data(bytesForAudioPacket))
          
            ////10. Add Sample to results
            results.append(sample)
          
            ////11. Calculate byte offset for start of next file
            nextFileByteOffset += sampleDef.length
        }
        
        return results
    }
    
    private static func loadDatafromURL(with url:URL) -> Data? {
        do {
           let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error: Can't load data:\(error.localizedDescription)")
            return nil
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
    
    private static func decodeJSONManifest(with manifestData:Data) -> AudioPackageManifest? {
        do {
            let packageManifest = try JSONDecoder().decode(AudioPackageManifest.self, from: manifestData)
            print("AudioPackage Samples: \(packageManifest.samples)")
            return packageManifest
        } catch {
            print("Error: Cannot serialize JSON:\(error)")
            return nil
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