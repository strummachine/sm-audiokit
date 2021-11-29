//
//  SampleEngine.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation

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
        samplePlayers = [.guitar: SamplePlayerPool(polyphonyLimit: polyphonyLimit, type: .guitar)]
        //// We can optionally init the other players as necessary
        ///
        
        //TODO:- Load sample bank from manifest
    }
    
    //// Do we really need to return a sample here?
    func loadSample(id: String, url: URL, type: SampleTypes, defaultVolume: Float = 1.0) -> Sample? {
        let sample = Sample(id: id, fileURL: url, type: type, defaultVolume: defaultVolume)
        sampleBank[id] = sample
        return sample
    }
    
    func playSample(sampleId: String,
                    channel: String,
                    playbackId: String,
                    at atTime: Float,
                    volume: Float?,
                    offset: Float?,
                    playbackRate: Float?,
                    pitchShift: Float?,
                    fadeInDuration: Double = 0) {
        
        guard let sample = self.sampleBank[sampleId] else { return }
        guard let player = self.samplePlayers[sample.type]?.getAvailablePlayer() else { return }
        
        player.play(sample: sample, channel: channel, playbackId: playbackId, at: atTime, volume: volume, offset: offset, playbackRate: playbackRate, pitchShift: pitchShift, fadeInDuration: fadeInDuration)
    }

//FIXME:- Need to put in fade scheduler into sampler
    
//    func fadePlayback(
//        playbackId: String,
//        atTime: AVAudioTime,
//        endVolume: Double,
//        fadeDuration: Double
//    ) {
//        let player = self.players?.getPlaybackById(playbackId)
//        player?.fade(at: atTime,
//                     to: endVolume,
//                     duration: fadeDuration)
//    }
    
    //TODO:- we can do better
    public func getAllNodes() -> [SamplePlayer] {
        var players: [SamplePlayer] = []
        samplePlayers.forEach {
            for player in $1.pool {
                players.append(player)
            }
        }
        return players
    }

}



