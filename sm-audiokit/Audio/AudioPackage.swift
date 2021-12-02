//
//  AudioPackage.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import CoreAudio
import AudioToolbox

class AudioPackageExtractor {
    
    public static func extractAudioPackage() -> [AudioPackage]? {
        ////1. Get path for audio-package file
        guard let pathForFile = Bundle.main.path(forResource: "testbed_mp3", ofType: "audio-package") else {
            fatalError("Can't open audio-package")
        }
        ////2. Convert to URL
        let url = URL(fileURLWithPath: pathForFile)
        
        ////3. Load contents of file into Data object
        guard let data = AudioPackageExtractor.loadDatafromURL(with: url) else {
            print("Error: Cannot load data from url")
            return nil
        }

        ////4. Convert Data to [UInt8] for easier access
        let bytes = data.bytes
        
        ////5. Extract JSON Manifest as Tuple of Data and Length
        let manifestResult = AudioPackageExtractor.extractJSONManifest(with: bytes)
        
        let manifestJSONData = manifestResult.0
        let manifestLength = manifestResult.1
        
        ////6. Decode JSON Manifest as AudioPackageSamples struct
        guard let audioPackageSamples = AudioPackageExtractor.decodeJSONManifest(with: manifestJSONData) else {
            return nil
        }

        ////7. Prep array of [AudioPackage] for successfull read and return
        var packages: [AudioPackage] = []
        
        ////8. Correct length for mp3 file parsing
        //// Manifest length - corrected length, + first 4 bytes of start of audio-package
        ////TODO:- This should probably be corrected at some point
        let adjustedManifestLength = ((manifestLength - 3) + 4)
        
        ////9. Loop through each sample to extract MP3 data from audio-package
        for (index, sample) in audioPackageSamples.samples.enumerated() {
            
            ////10. Get current bytes read to read mp3 chunk properly
            let totalBytesReadUntilNow = audioPackageSamples.samples[0..<index].map(\.length).reduce(0, +)
            var bytesForAudioPacket: [UInt8] = []
            
            //print("Range: \((adjustedManifestLength+totalBytesReadUntilNow ..< adjustedManifestLength+totalBytesReadUntilNow+sample.length))")
            
            ////11. Check between mp3 chunks and store data into temporary array.
            for i in ( (adjustedManifestLength + totalBytesReadUntilNow) ..< (adjustedManifestLength+totalBytesReadUntilNow + sample.length) ) {
                bytesForAudioPacket.append(bytes[i])
            }
            
            ////12. Write the MP3 file to disk, this is easier than putting into CoreAudioBuffer
            ///TODO:- may do if let here if we want to allow some failures to write, however
            ///letting the whole function return nil is probably what we want if we can't successfully write a file.
            guard let url = AudioPackageExtractor.writeFileToDisk(with: Data(bytesForAudioPacket), and: sample.name) else {
                print("Error: Cannot write file to disk")
                return nil
            }
            packages.append(.init(sample: sample, mp3Data: Data(bytesForAudioPacket), url: url))
        }
        
        print("packages: \(packages.map(\.mp3Data.count))")
        return packages
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
        
        var length: Int = Int(manifestLength)
        //TODO:- I still don't know why we are missing 3 bytes for the JSON Payload, we actually need to omit these during the mp3 data extraction so this is a very weird problem
        length += 3
        
        let manifestJSON = bytes[4...length]
        let manifestJSONString = "{\"samples\" : \(String(decoding: manifestJSON, as: UTF8.self))}"
        print(manifestJSONString)

        return (Data(manifestJSONString.utf8),length)
    }
    
    private static func decodeJSONManifest(with manifestData:Data) -> AudioPackageSamples? {
        do {
            let audioPackageSamples = try JSONDecoder().decode(AudioPackageSamples.self, from: manifestData)
            print("AudioPackage Samples: \(audioPackageSamples.samples)")
            return audioPackageSamples
        } catch {
            print("Error: Cannot serialize JSON:\(error)")
            return nil
        }
    }
    
    private static func writeFileToDisk(with mp3Data: Data,and name: String) -> URL? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(name).mp3")
        
        do {
            try mp3Data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("ERROR: cannot write mp3:\(error)")
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

struct AudioPackage {
    let sample: AudioPackageSample
    let mp3Data: Data
    let url: URL
}

struct AudioPackageSamples: Codable {
    let samples: [AudioPackageSample]
}

struct AudioPackageSample: Codable {
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
