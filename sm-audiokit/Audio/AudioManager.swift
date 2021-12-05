//
//  AudioManager.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/25/21.
//

import Foundation
import AudioKit
import AVFAudio
import AudioKitEX

class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()

    let mainMixer: Mixer
    var audioPlayer: AudioPlayer = AudioPlayer()

    var channels = [String: Channel]()
    var playbacks = [String: SamplePlayback]()
    var sampleBank = [String: Sample]()
    
    var browserTimeOffset: Float = 0.0

    init() {
        mainMixer = Mixer(audioPlayer)
        engine.output = mainMixer
    }

    func loadTestPackage() {
        guard let samples = AudioPackageExtractor.extractAudioPackage() else {
            fatalError("Error: Cannot unwrap audioPackages")
        }
        for sample in samples {
            sampleBank[sample.id] = sample
        }
    }

    // Not using for now
    func loadPackages(packagePaths: [String]) {
//        for path in packagePaths {
//            guard let samples = AudioPackageExtractor.extractAudioPackage(path: path) else {
//                fatalError("Error: Cannot unwrap audioPackages")
//            }
//            for sample in samples {
//                sampleBank[sample.id] = sample
//            }
//        }
    }

    func loadSample(sampleId: String, audioData: Data) {
        let sample = SampleStorage.storeSample(sampleId: sampleId, audioData: audioData)
        sampleBank[sample.id] = sample
    }

    func setupChannels(_ channelNames: [String]) {
        for channelName in channelNames {
            channels[channelName] = Channel(id: channelName, mainMixer: self.mainMixer)
        }
    }

    public func start() {
        do {
            try engine.start()
        } catch {
            print("Error: Cannot start audio engine: \(error.localizedDescription)")
        }
    }
    public func stop() {
        engine.stop()
    }

    // MARK:- Sample playback

    func playSample(sampleId: String,
                    channel: String,
                    playbackId: String,
                    atTime: Float,
                    volume: Float = 1.0,
                    offset: Float = 0.0,
                    playbackRate: Float = 1.0,
                    fadeInDuration: Float = 0.0) {
        // Grab sample and channel
        // TODO: this should probably throw if either isn't found
        guard let sample = self.sampleBank[sampleId] else { return }
        guard let channel = self.channels[channel] else { return }

        guard let playback = SamplePlayback(
            sample: sample,
            channel: channel,
            playbackId: playbackId,
            volume: volume,
            offset: offset,
            playbackRate: playbackRate,
            fadeInDuration: fadeInDuration
        ) else { return }
        
//        guard let startTime = convertAtTimeForSyncedPlayback(at: atTime, masterPlayer: self.mainMixer.avAudioNode) else {
//            return
//        }
//        playback.play(from: offset, at: startTime)
        playback.play()
        playbacks[playbackId] = playback
        // TODO: Remove playback from dictionary when completed? (for GC?)
    }

    //MARK:- Playback manipulation

    func setPlaybackVolume(playbackId: String, atTime: Float, volume: Float, fadeDuration: Float) {
        playbacks[playbackId]?.fade(at: atTime, to: volume, duration: fadeDuration)
    }

    // This one doesn't need to be implemented for v1
    func setPlaybackRate(playbackId: String, atTime: Float, playbackRate: Float, transitionDuration: Float) {
        playbacks[playbackId]?.changePlaybackRate(at: atTime, to: playbackRate, duration: transitionDuration)
    }

    func stopPlayback(playbackId: String, atTime: Float, fadeDuration: Float = 0.0) {
        if fadeDuration > 0 {
          playbacks[playbackId]?.fade(at: atTime, to: 0, duration: fadeDuration)
        }
        playbacks[playbackId]?.stop(at: atTime)
    }

    // MARK: Channels
    func setChannelVolume(channel: String, volume: Float) {
      // TODO: Is the change instantaneous or is there already a short ramp?
        channels[channel]?.setVolume(volume)
    }

    func setChannelPan(channel: String, pan: Float) {
        channels[channel]?.setPan(pan)
    }

    func setChannelMuted(channel: String, muted: Bool) {
        channels[channel]?.setMuted(muted)
    }

    func setMasterVolume(volume: Float) {
        mainMixer.volume = volume
    }

    // MARK: Time Conversion (move elsewhere?)

    func convertAtTimeForSyncedPlayback(at atTime: Float, masterPlayer: AVAudioNode) -> AVAudioTime? {
        // TODO: Implement browserTime conversion
        
        ////1. Get the output format (really sampleRate)
        let outputFormat = masterPlayer.outputFormat(forBus: 0)
        
        // TODO: need to take browserTimeOffset into account here most likely
        let scheduledTime = atTime
        ////2. Multiple our scheduled time (when we want the file to play) by the output sample rate
        let scheduledSampleTime = Int64(scheduledTime * Float(outputFormat.sampleRate))
        
        ////3. Get frame position time of the main player
        guard let playerFramePositionTime = masterPlayer.lastRenderTime?.sampleTime else {
            print("Error: cannot unwrap sample time from master player lastRenderTime.sampleTime")
            return nil
        }
        
        ////4. Create AVAudioFramePosition of the Scheduled Sample Time and the player's frame position
        let finalSampleTime = AVAudioFramePosition(playerFramePositionTime + scheduledSampleTime)
        
        ////5. Return new AVAudioTime object, this AVAudioTime needs to be used for all players playing
        ////   simultaneously
        return AVAudioTime(sampleTime: finalSampleTime, atRate: outputFormat.sampleRate)
    }

    func setBrowserTime(_ browserTime: Float) {
        // TODO: calculate and store offset between browserTime and audio clock
        let iPhoneNow: Float = Float(DispatchTime.now().rawValue)
        browserTimeOffset = iPhoneNow - browserTime
    }

    //func prepareSamplersFor

  }
