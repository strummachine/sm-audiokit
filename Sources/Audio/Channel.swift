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
    var playerPool: SamplePlayerPool

    init(id: String, polyphonyLimit: Int, mainMixer: Mixer) {
        self.id = id
        self.mixer = Mixer(volume: 1.0, name: "channel:\(id)")
        self.playerPool = SamplePlayerPool(size: polyphonyLimit)
        for player in self.playerPool.players {
            self.mixer.addInput(player.outputNode)
        }
        mainMixer.addInput(self.mixer)
    }

    func getPlayer(forSample sample: Sample) -> SamplePlayer {
        return self.playerPool.getPlayer(forSample: sample)
    }
    
    public func stopAllPlayers() {
        self.playerPool.stopAllPlayers()
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
