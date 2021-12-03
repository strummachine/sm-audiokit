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
    
    init(id: String, mainMixer: Mixer) {
        self.id = id
        self.mixer = Mixer()
        mainMixer.addInput(self.mixer)
    }
    
    func attach(player: AudioPlayer, outputNode: Node) {
        self.mixer.addInput(outputNode)
      
        // TODO: is this necessary? seems harmless at the very least,
        // and possibly necessary to avoid a memory leak...?
        player.completionHandler = {
            self.mixer.removeInput(outputNode)
        }
    }
  
  func setVolume(_ volume: Float) {
      mixer.volume = volume
  }
  
  func setPan(_ pan: Float) {
      mixer.pan = pan
  }
}



