//
//  SampleEngine.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation
import AudioKitEX

enum SampleTypes: String {
    case guitar = "Guitar"
    case bass = "Bass"
    case drums = "Drums"
}

class SampleManager {

    var engineStarted = false
    
    var polyphonyLimit: Int = 20
    var samplePlayers: [SampleTypes: SamplePlayerPool]
    var sampleBank = [String: Sample]()
    
    //TODO:- I think the wisest thing here is we can init with the AudioPackage manifest!
    init() {
        guard let audioPackages = AudioPackageExtractor.extractAudioPackage() else {
            fatalError("Error: Cannot unwrap audioPackages")
        }
        
        for package in audioPackages {
            var type: SampleTypes
            if package.sample.name.contains("--") {
                type = .guitar
            }
            else {
                type = .drums
            }
            
            sampleBank[package.sample.name] = Sample(id: package.sample.name, fileURL: package.url, type: type)
        }
        samplePlayers = [.guitar: SamplePlayerPool(polyphonyLimit: polyphonyLimit, type: .guitar)]
        samplePlayers[.drums] = SamplePlayerPool(polyphonyLimit: polyphonyLimit, type: .drums)
        
        //// We can optionally init the other players as necessary
        ///
        
        //TODO:- Load sample bank from manifest
    }
    
    //// Do we really need to return a sample here?
    ///
    ///No, we need durations and potentially that it loaded correctly
    func loadSample(id: String, url: URL, type: SampleTypes, defaultVolume: Float = 1.0) {
        let sample = Sample(id: id, fileURL: url, type: type, defaultVolume: defaultVolume)
        sampleBank[id] = sample
        
        //TODO:- Return enum status or tuple with duration, maybe special json stuct so it can talk with Cordova?
    }
    
    func playSample(sampleId: String,
                    channel: String,
                    playbackId: String,
                    at atTime: Float,
                    volume: Float? = 1.0,
                    offset: Float? = 0.0,
                    playbackRate: Float? = 1.0,
                    pitchShift: Float? = 0.0,
                    fadeInDuration: Double? = 0.0) {
        
        guard let sample = self.sampleBank[sampleId] else { return }
        guard let player = self.samplePlayers[sample.type]?.getAvailablePlayer() else { return }
        
        player.load(sample: sample, channel: "1", playbackId: "1", at: 0)
        
//        player.play(sample: sample, channel: channel, playbackId: playbackId, at: atTime, volume: volume, offset: offset, playbackRate: playbackRate, pitchShift: pitchShift, fadeInDuration: fadeInDuration)
    }
        
    public func attachSamplePlayersToMixer(mixer: Mixer) {
        samplePlayers.forEach {
            for player in $1.pool {
                mixer.addInput(player.outputNode)
            }
        }
    }

}



