//
//  Sample.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AVFoundation

class Sample {
    var id: String
    var url: URL
    var duration: Double

    init(id: String, url: URL, duration: Double) {
        self.id = id
        self.url = url
        self.duration = duration
    }

    private var buffer: AVAudioPCMBuffer?
    func getBuffer(forPlayer player: AVAudioPlayerNode) throws -> AVAudioPCMBuffer {
        if self.buffer == nil {
            let startTime = AVAudioTime.seconds(forHostTime: mach_absolute_time())
            let file = try AVAudioFile(forReading: self.url)
            let fileBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                              frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: fileBuffer)

            let destBuffer = AVAudioPCMBuffer(pcmFormat: player.outputFormat(forBus: 0), frameCapacity: AVAudioFrameCount(file.duration * player.outputFormat(forBus: 0).sampleRate))!
            let converter = AVAudioConverter(from: file.processingFormat, to: player.outputFormat(forBus: 0))!

            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return fileBuffer
            }

            var error: NSError? = nil
            let status = converter.convert(to: destBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)
            let endTime = AVAudioTime.seconds(forHostTime: mach_absolute_time())
            print("Decoding", file.url.lastPathComponent.padding(toLength: 30, withPad: " ", startingAt: 0), Int(file.processingFormat.sampleRate), Int((endTime - startTime) * 1000))

            self.buffer = destBuffer
        }
        return self.buffer!
//        let bufferCopy = AVAudioPCMBuffer(pcmFormat: self.buffer!.format, frameCapacity: self.buffer!.frameLength)!
//        bufferCopy.copy(from: self.buffer!)
//        return bufferCopy
    }
}

