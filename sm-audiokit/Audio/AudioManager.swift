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

    var browserTimeOffset = Double()
    
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
                    atTime: Double,
                    volume: Float = 1.0,
                    offset: Float = 0.0,
                    playbackRate: Float = 1.0,
                    fadeInDuration: Float = 0.0) throws -> SamplePlayback {
        // Grab sample and channel
        
        guard let sample = self.sampleBank[sampleId] else {
            throw AudioManagerError.cannotFindSample(sampleId: sampleId)
        }
        guard let channel = self.channels[channel] else {
            throw AudioManagerError.cannotFindChannel(channel: channel)
        }

        let startTime = browserTimeToAudioTime(atTime)

        do {
            let playback = try SamplePlayback(
                sample: sample,
                channel: channel,
                playbackId: playbackId,
                atTime: startTime,
                volume: volume,
                offset: offset,
                playbackRate: playbackRate,
                fadeInDuration: fadeInDuration
            )
            // TODO: Remove playback from dictionary when completed? (for GC?)
            playbacks[playbackId] = playback
            return playback
        } catch let error as SamplePlaybackError {
            throw error
        } catch let error as Error {
            //Generic Error Handling
            throw error
        }
    }

    // MARK: Playback manipulation

    func setPlaybackVolume(playbackId: String, atTime: Double, volume: Float, fadeDuration: Float) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.fade(at: time, to: volume, duration: fadeDuration)
    }

    // This one doesn't need to be implemented for v1
    func setPlaybackRate(playbackId: String, atTime: Double, playbackRate: Float, transitionDuration: Float) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.changePlaybackRate(at: time, to: playbackRate, duration: transitionDuration)
    }

    func stopPlayback(playbackId: String, atTime: Double, fadeDuration: Float = 0.0) {
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
}

// MARK: - Audio Clock Timing Methods
extension AudioManager {
    private func getMasterClockSeconds() throws -> Double {
        guard let mainMixerNode = self.engine.mainMixerNode else {
            throw AudioManagerError.cannotUnwrapMainMixerNode
        }
        guard let lastRenderTime = mainMixerNode.avAudioNode.lastRenderTime else {
            throw AudioManagerError.cannotUnwrapLastRenderTime
        }
        return AVAudioTime.seconds(forHostTime: lastRenderTime.hostTime)
    }
    
    public func browserTimeToAudioTime(_ browserTime: Double) -> AVAudioTime {
        // TODO: Implement browserTime conversion
        return AVAudioTime(hostTime: 0).offset(seconds: self.browserTimeOffset + browserTime)
    }

    public func setBrowserTime(_ browserTime: Double) throws {
        do {
            let audioEngineHostTime = try getMasterClockSeconds()
            self.browserTimeOffset = audioEngineHostTime - browserTime
        } catch let error as AudioManagerError {
            throw error
        } catch {
            //Generic Error handling
        }
    }
}
