//
//  SampleEngine.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation
import AudioKit
import AVFoundation

class SampleEngine {

  var engineStarted = false

  var polyphonyLimit: Int = 20
  var players: SamplePlayerPool?

  var sampleBank = [String: Sample]()
  
  init () {
    
  }

  var masterVolume: Float = 1.0 {
    didSet {
//      masterMixer.outputVolume = masterVolume
    }
  }

  func startEngine(polyphonyLimit: Int = 20) {
    if engineStarted { return }
    engineStarted = true

    // configureAudioSession()
    // configureNotificationCenterObservers()

    // engine.attach(masterMixer)
    // engine.connect(masterMixer, to: engine.mainMixerNode, format: nil)

    players = SamplePlayerPool(/* TODO: pass in polyphonyLimit */)

    // restartEngine()

    try? AudioKit.start()
  }

  // func restartEngine() {
  //   if !engine.isRunning {
  //     do {
  //       try engine.start()
  //     } catch let error {
  //       print("AVAudioEngine did not start")
  //       print(error.localizedDescription)
  //     }
  //   }
  // }

  func loadSample(
                  id: String,
                  url: URL,
                  defaultVolume: Double = 1
                ) -> Sample {
    if !engineStarted {
      startEngine()
    }

    let sample = Sample(id: id, fileURL: url, defaultVolume: defaultVolume)
    sampleBank[id] = sample
    return sample
  }

  func playSample(
                  sampleId: String,
                  playbackId: String,
                  atTime: AVAudioTime,
                  offset: Double = 0,
                  playbackRate: Double = 1,
                  volume: Double = 1,
                  playDuration: Double,
                  fadeInDuration: Double = 0
                ) {
    guard let player = self.players!.getAvailablePlayer() else { return }
    guard let sample = self.sampleBank[sampleId] else { return }
    player.play(
      sample: sample,
      playbackId: playbackId,
      at: atTime,
      offset: offset,
      playbackRate: playbackRate,
      volume: volume,
      playDuration: playDuration,
      fadeInDuration: fadeInDuration
    )
  }

  func fadePlayback(
                  playbackId: String,
                  atTime: AVAudioTime,
                  endVolume: Double,
                  fadeDuration: Double
                ) {
    let player = self.players?.getPlaybackById(playbackId)
    player?.fade(at: atTime,
                to: endVolume,
                duration: fadeDuration)
  }

}



