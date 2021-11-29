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
    var lastUsedPlayerIndex = 0
    var polyphonyLimit: Int

    init(polyphonyLimit: Int = 30) {
        self.polyphonyLimit = polyphonyLimit
        for _ in 0..<polyphonyLimit {
            let player = SamplePlayer()
            self.pool.append(player)
        }
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

}

