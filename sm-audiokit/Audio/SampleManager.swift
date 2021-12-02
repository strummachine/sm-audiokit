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

class SampleManager {

    var engineStarted = false
    
    var polyphonyLimit: Int = 20
    var samplePlayers: SamplePlayerPool
    var sampleBank = [String: Sample]()
    
    //TODO:- I think the wisest thing here is we can init with the AudioPackage manifest!
    init() {
        guard let samples = AudioPackageExtractor.extractAudioPackage() else {
            fatalError("Error: Cannot unwrap audioPackages")
        }
        
        for sampleInfo in samples {
          sampleBank[sampleInfo.id] = Sample(id: sampleInfo.id, url: sampleInfo.url, duration: sampleInfo.duration)
        }
        samplePlayers = SamplePlayerPool(polyphonyLimit: polyphonyLimit)
        
        //// We can optionally init the other players as necessary
        
        //TODO:- Load sample bank from manifest
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
        guard let player = self.samplePlayers.getAvailablePlayer() else { return }
        
        player.load(sample: sample, channel: "1", playbackId: "1", at: 0)
        
//        player.play(sample: sample, channel: channel, playbackId: playbackId, at: atTime, volume: volume, offset: offset, playbackRate: playbackRate, pitchShift: pitchShift, fadeInDuration: fadeInDuration)
    }
        
    public func attachSamplePlayersToMixer(mixer: Mixer) {
        for player in samplePlayers.pool {
            mixer.addInput(player.outputNode)
        }
    }

}



