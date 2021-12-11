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
    let fader: Fader
    let mixer: Mixer

    init(id: String, mainMixer: Mixer) {
        self.id = id
        self.mixer = Mixer(name: "channel:\(id)")
        self.fader = Fader(self.mixer)
        mainMixer.addInput(self.fader)
    }

    private var _volume = 1.0
    var volume: Double {
        get {
            return _volume
        }
        set {
            _volume = newValue
            let newVolume = Float(_muted ? 0.0 : _volume)
            fader.stopAutomation()
            fader.$leftGain.ramp(to: newVolume, duration: 0.25)
            fader.$rightGain.ramp(to: newVolume, duration: 0.25)
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
            fader.stopAutomation()
            fader.$leftGain.ramp(to: newVolume, duration: 0.25)
            fader.$rightGain.ramp(to: newVolume, duration: 0.25)
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
