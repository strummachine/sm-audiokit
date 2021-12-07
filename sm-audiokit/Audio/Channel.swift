//
//  Channel.swift
//  sm-audiokit
//
//  Created by Luke Abbott on 12/2/21.
//

import Foundation
import AudioKit
import AVFoundation
import AudioKitEX

class Channel {
    let id: String
    let mixer: Mixer
    var polyphonyLimit: Int
    var playerPool = [SamplePlayer]()

    init(id: String, polyphonyLimit: Int, mainMixer: Mixer) {
        self.id = id
        self.polyphonyLimit = polyphonyLimit
        self.mixer = Mixer(volume: 1.0, name: "channel:\(id)")
        mainMixer.addInput(self.mixer)
        for _ in 0..<polyphonyLimit {
            let player = SamplePlayer(channel: self)
            self.mixer.addInput(player.outputNode)
            self.playerPool.append(player)
        }
    }

    func getPlayer(forSample sample: Sample) -> SamplePlayer {
        let debugPreloadedCount = self.playerPool.filter({ $0.available && $0.sampleId == sample.id }).count
        print("Getting player from channel:\(self.id) - \(self.playerPool.filter({ $0.available }).count) of \(self.polyphonyLimit) available, \(debugPreloadedCount > 0 ? String(debugPreloadedCount) : "ZERO") ready with \(sample.id)  <-- LOADING")
        let playerWithSampleLoaded = self.playerPool.first(where: { $0.available && $0.sampleId == sample.id })
        if playerWithSampleLoaded != nil {
            return playerWithSampleLoaded!
        }
        let sortedPlayers = self.playerPool.sorted { a, b in
            return ((a.startTime?.hostTime ?? 0) < (b.startTime?.hostTime ?? 0))
        }
        return sortedPlayers.first(where: { $0.available && $0.sampleId == nil })
            ?? sortedPlayers.first(where: { $0.available })
            ?? sortedPlayers.first!
    }

    private var _volume = 1.0
    var volume: Double {
        get {
            return _volume
        }
        set {
            _volume = newValue
            // TODO: Ramp volume over 50-80ms to avoid clicks
            mixer.volume = Float(_muted ? 0.0 : _volume)
        }
    }

    private var _muted = false
    var muted: Bool {
        get {
            return _muted
        }
        set {
            _muted = newValue
            // TODO: Ramp over 50-80ms to avoid clicks
            mixer.volume = Float(_muted ? 0.0 : _volume)
        }
    }

    var pan: Double {
        get {
            return Double(mixer.pan)
        }
        set {
            // TODO: Ramp over 50-80ms to avoid clicks
            mixer.pan = Float(newValue)
        }
    }
}
