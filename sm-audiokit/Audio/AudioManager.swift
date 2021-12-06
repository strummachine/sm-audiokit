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

    var browserTimeOffset = UInt64()
    
    init() {
        mainMixer = Mixer()
        engine.output = mainMixer
    }

    func loadTestPackage() {
        do {
            let samples = try AudioPackageExtractor.extractAudioPackage()
            for sample in samples {
                sampleBank[sample.id] = sample
            }
        } catch {
            print(error.localizedDescription)
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

    func loadSample(sampleId: String, audioData: Data) throws -> Sample {
        let sampleTuple = SampleStorage.storeSample(sampleId: sampleId, audioData: audioData)
        if let sample = sampleTuple.0 {
            sampleBank[sample.id] = sample
            return sample
        }
        else {
            if let error = sampleTuple.1 {
                throw error
            }
            else {
                throw AudioPackageError.unknownError
            }
        }
    }

    func setupChannels(_ channelNames: [String]) {
        for channelName in channelNames {
            channels[channelName] = Channel(id: channelName, mainMixer: self.mainMixer)
        }
    }

    public func start() throws {
        do {
            try engine.start()
        } catch {
            throw AudioManagerError.audioEngineCannotStart(error: error)
        }
    }
    public func stop() {
        engine.stop()
    }

    // MARK: Sample playback

    func playSample(sampleId: String,
                    channel: String,
                    playbackId: String,
                    atTime: Float,
                    volume: Float = 1.0,
                    offset: Float = 0.0,
                    playbackRate: Float = 1.0,
                    fadeInDuration: Float = 0.0) throws -> SamplePlayback? {
        // Grab sample and channel
        
        guard let sample = self.sampleBank[sampleId] else {
            throw AudioManagerError.cannotFindSample(sampleId: sampleId)
        }
        guard let channel = self.channels[channel] else {
            throw AudioManagerError.cannotFindChannel(channel: channel)
        }

        let startTime = browserTimeToAudioTime(atTime)

        let playback = SamplePlayback(
            sample: sample,
            channel: channel,
            playbackId: playbackId,
            atTime: startTime,
            volume: volume,
            offset: offset,
            playbackRate: playbackRate,
            fadeInDuration: fadeInDuration
        )!
        
        playbacks[playbackId] = playback
        // TODO: Remove playback from dictionary when completed? (for GC?)
        return playback
    }

    // MARK: Playback manipulation

    func setPlaybackVolume(playbackId: String, atTime: Float, volume: Float, fadeDuration: Float) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.fade(at: time, to: volume, duration: fadeDuration)
    }

    // This one doesn't need to be implemented for v1
    func setPlaybackRate(playbackId: String, atTime: Float, playbackRate: Float, transitionDuration: Float) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.changePlaybackRate(at: time, to: playbackRate, duration: transitionDuration)
    }

    func stopPlayback(playbackId: String, atTime: Float, fadeDuration: Float = 0.0) {
        let time = browserTimeToAudioTime(atTime)
        if fadeDuration > 0 {
          playbacks[playbackId]?.fade(at: time, to: 0, duration: fadeDuration)
        }
        playbacks[playbackId]?.stop(at: time.offset(seconds: Double(fadeDuration)))
    }

    // MARK: Channels

    func setChannelVolume(channel: String, volume: Float) {
      // TODO: Is the change instantaneous or is there already a short ramp
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

    func browserTimeToAudioTime(_ browserTime: Float) -> AVAudioTime {
        // TODO: Implement browserTime conversion
        return AVAudioTime(hostTime: UInt64(browserTime * 1000 * 1000 * 1000) + self.browserTimeOffset)
    }

    func setBrowserTime(_ browserTime: Float) {
        // TODO: calculate and store offset between browserTime and audio clock
        self.browserTimeOffset = self.engine.mainMixerNode!.avAudioNode.lastRenderTime!.hostTime - browserTime.hostTime;)
    }
}
