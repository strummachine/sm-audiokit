//
//  SamplePlayerPool.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation

class SamplePlayerPool {

    var pool = [SamplePlayer]()
    var polyphonyLimit: Int
    let type: SampleTypes
    
    init(polyphonyLimit: Int = 30, type: SampleTypes) {
        self.polyphonyLimit = polyphonyLimit
        for _ in 0..<polyphonyLimit {
            let player = SamplePlayer()
            self.pool.append(player)
        }
        self.type = type
    }

    func getAvailablePlayer() -> SamplePlayer? {
        
        if let playerToReturn = pool.first(where: {!$0.isPlaying }) {
            return playerToReturn
        }
        else {
            print("All sample players are busy. Increase polyphonyLimit in startEngine call")
            return nil
        }
    }

    func getPlaybackById(_ id: String) -> SamplePlayer? {
        return pool.first { $0.playbackId == id }
    }

    //TODO:- Need parameters to determine which samplers are to play back
    public func scheduleSynchronizedPlayback(with delayTime: Float, at startTime: Float) {
        
//        //// Sample-frame accurate sync:
//        ///
//        
//        //FIXME:- We will have a dedicated method for this, this is temporary.
//        guard let masterPlayer = self.getAvailablePlayer() else {
//            return
//        }
//        
//        let avStartTime:
//        
//        let outputFormat = masterPlayer.player.avAudioNode.outputFormat(forBus: 0)
//        guard let now = masterPlayer.player.avAudioNode.lastRenderTime?.sampleTime else {
//            return
//        }
//        
//        //FIXME:- Need to convert floats to AVFrameTime in order to do math properly.
//        let startTime = AVAudioTime(sampleTime: ((now + startTime) +(delayTime * outputFormat.sampleRate)), atRate: outputFormat.sampleRate)
//        
//        //TODO:- play players with start time:
    }
}

