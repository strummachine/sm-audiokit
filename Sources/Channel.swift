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
    var playerPool = SamplePlayerPool()

    init(id: String, polyphonyLimit: Int, mainMixer: Mixer) {
        self.id = id
        self.mixer = Mixer(name: "channel:\(id)")
        mainMixer.addInput(self.mixer)
        self.playerPool.createPlayers(count: polyphonyLimit)
        for player in self.playerPool.players {
            self.mixer.addInput(player.outputNode)
        }
    }

    private var _volume = 1.0
    var volume: Double {
        get {
            return _volume
        }
        set {
            _volume = newValue
            let newVolume = Float(_muted ? 0.0 : _volume)
            mixer.volume = newVolume
        }
    }

    private var _muted = false
    var muted: Bool {
        get {
            return _muted
        }
        set {
            _muted = newValue
            let newVolume = Float(_muted ? 0.0 : _volume)
            mixer.volume = newVolume
        }
    }

    var pan: Double {
        get {
            return Double(mixer.pan)
        }
        set {
            // TODO: Ramp over 50-80ms to avoid clicks (maybe)
            mixer.pan = Float(newValue)
        }
    }
}

struct ChannelDefinition {
    let id: String
    let polyphonyLimit: Int
}
