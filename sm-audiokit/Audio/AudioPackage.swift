//
//  AudioPackage.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import CoreAudio
import AudioToolbox

struct Parser {
        private var data: Data
        init(data: Data) {
                self.data = data
        }
        private mutating func parseLEUIntX<Result>(_: Result.Type) -> Result?
                where Result: UnsignedInteger
        {
                let expected = MemoryLayout<Result>.size
                guard data.count >= expected else { return nil }
                defer { self.data = self.data.dropFirst(expected) }
                return data
                        .prefix(expected)
                        .reversed()
                        .reduce(0, { soFar, new in
                                (soFar << 8) | Result(new)
                        })
        }
        mutating func parseLEUInt8() -> UInt8? {
                parseLEUIntX(UInt8.self)
        }
        mutating func parseLEUInt16() -> UInt16? {
                parseLEUIntX(UInt16.self)
        }
        mutating func parseLEUInt32() -> UInt32? {
                parseLEUIntX(UInt32.self)
        }
        mutating func parseLEUInt64() -> UInt64? {
                parseLEUIntX(UInt64.self)
        }
}
/*
 extractAudioPackage(arrayBuffer) {
   const bufferByteView = new DataView(arrayBuffer);
   const manifestLength = bufferByteView.getInt32(0, false);
   const manifestBinary = new Uint8Array(arrayBuffer, 4, manifestLength);
   const manifestJSON = new TextDecoder('utf-8').decode(manifestBinary);
   const manifest = JSON.parse(manifestJSON);

   let files = new Map();
   let byteOffset = 4 + manifestLength;
   manifest.forEach((file) => {
     files.set(file.name, arrayBuffer.slice(byteOffset, byteOffset + file.length));
     byteOffset += file.length;
   });
   return files;
 }
 */

struct AudioPackage {
    
    var data: Data?
    
    init?() {
        guard let pathForFile = Bundle.main.path(forResource: "testbed_mp3", ofType: "audio-package") else {
            fatalError("Can't open audio-package")
        }
        
        let url = URL(fileURLWithPath: pathForFile)
        
        do {
            data = try Data(contentsOf: url)
        } catch {
            print("Error: Can't load data:\(error.localizedDescription)")
            return nil
        }
    }
    
    public func extractAudioPackage() -> URL? {

        guard let data = data else {
            fatalError("Cannot unwrap data")
        }
        let bytes = data.bytes
        let manifestLengthArray: [UInt8] = Array(bytes[..<4])
        let manifestLength = manifestLengthArray.reduce(0) { soFar, byte in
            return soFar << 8 | Int32(byte)
        }
        print("LENGTH:\(manifestLength)")
        
        var length: Int = Int(manifestLength)
        length += 3
        let manifestJSON = bytes[4...length]
        let manifestJSONString = "{\"packets\" : \(String(decoding: manifestJSON, as: UTF8.self))}"
        
        print(manifestJSONString)
        let manifestJSONData = Data(manifestJSONString.utf8)

        do {
            let audioPackets = try JSONDecoder().decode(AudioPackets.self, from: manifestJSONData)
            print("audio packets: \(audioPackets.packets)")
            var recordings: [AudioRecording] = []
            for (index, packet) in audioPackets.packets.enumerated() {
                let totalBytesReadUntilNow = audioPackets.packets[0..<index].map(\.length).reduce(0, +)
                var bytesForAudioPacket: [UInt8] = []
                let actualLength = length - 3
                print("Range: \((4+actualLength+totalBytesReadUntilNow ..< 4+actualLength+totalBytesReadUntilNow+packet.length))")
                for i in (4+actualLength+totalBytesReadUntilNow ..< 4+actualLength+totalBytesReadUntilNow+packet.length) {
                    bytesForAudioPacket.append(bytes[i])
                }
                recordings.append(.init(packet: packet, mp3Data: Data(bytesForAudioPacket)))
            }
            
            print("recordings: \(recordings.map(\.mp3Data.count))")
            let url = writeFileToDisk(with: recordings[0])
            return url
        } catch {
            print("ERROR: cannot serizlize json:\(error.localizedDescription)")
        }
        return nil
    }
    
    public func writeFileToDisk(with recording: AudioRecording) -> URL? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(recording.packet.name).mp3")
        
        do {
            try recording.mp3Data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("ERROR: cannot write mp3:\(error)")
            return nil
        }
        
    }
    
//    public func audioFileReaderWithData(audioData: Data) {
//        var refAudioFileID: AudioFileID
//        var inputFileID: ExtAudioFileRef
//        var outputFileID: ExtAudioFileRef
//
//        var result: OSStatus = AudioFileOpenWithCallbacks(audioData, AudioFile_ReadProc.self, 0, AudioFile_GetSizeProc.self, 0, kAudioFileMP3Type, &refAudioFileID)
//    }
}



struct AudioPackets: Codable {
    let packets: [AudioPacket]
}

struct AudioPacket: Codable {
    let name: String
    let length: Int
}

struct AudioRecording {
    let packet: AudioPacket
    let mp3Data: Data
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
