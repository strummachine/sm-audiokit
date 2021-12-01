//
//  AudioPackage.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation

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
    
    public func extractAudioPackage() {

        guard let data = data else {
            fatalError("Cannot unwrap data")
        }
        let bytes = data.bytes
        let manifestLengthArray = Array(bytes[...3])
        let manifestLength: UInt32 = manifestLengthArray.object()
       
        let manifestBinary = Array(bytes[4...])
        let manifestString = String(decoding: manifestBinary, as: UTF8.self)
        
        let manifestBinaryData = Data(manifestString.utf8)
        
        do {
            let jsonData = try JSONSerialization.jsonObject(with: manifestBinaryData, options: []) as? [String: Any]
//            let jsonString = String(decoding: jsonData, as: UTF8.self)
//            print("STRING:\(jsonString)")
            print(jsonData?.debugDescription)
        } catch {
            print("ERROR: cannot serizlize json:\(error.localizedDescription)")
        }
    }
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
