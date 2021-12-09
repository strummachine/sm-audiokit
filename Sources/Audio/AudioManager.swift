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
    
    internal var notifier = NotificationCenter.default
    
    init() {
        mainMixer = Mixer(volume: 1.0, name: "master")
        registerForNotifications()
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

    func createChannel(id: String, polyphonyLimit: Int = 16) {
        self.channels[id] = Channel(id: id, polyphonyLimit: polyphonyLimit, mainMixer: self.mainMixer)
    }

    public func start() throws {
        do {
            try engine.start()
            print("Started Audio Engine")
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
                    volume: Double = 1.0,
                    offset: Double = 0.0,
                    playbackRate: Double = 1.0,
                    fadeInDuration: Double = 0.0) throws -> SamplePlayback {
        // Grab sample and channel
        
        guard let sample = self.sampleBank[sampleId] else {
            throw AudioManagerError.cannotFindSample(sampleId: sampleId)
        }
        guard let channel = self.channels[channel] else {
            throw AudioManagerError.cannotFindChannel(channel: channel)
        }

        let startTime = browserTimeToAudioTime(atTime)

        do {
            let player = channel.getPlayer(forSample: sample)
            let playback = try player.schedulePlayback(
                sample: sample,
                playbackId: playbackId,
                atTime: startTime,
                volume: volume,
                offset: offset,
                playbackRate: playbackRate,
                fadeInDuration: fadeInDuration
            )
            playbacks[playbackId] = playback
            return playback
        } catch let error as SamplePlaybackError {
            throw error
        } catch {
            //Generic Error Handling
            throw error
        }
    }

    // MARK: Playback manipulation

    func setPlaybackVolume(playbackId: String, atTime: Double, volume: Double, fadeDuration: Double) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.fade(at: time, to: volume, duration: fadeDuration)
    }

    // This one doesn't need to be implemented for v1
    func setPlaybackRate(playbackId: String, atTime: Double, playbackRate: Double, transitionDuration: Double) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.changePlaybackRate(at: time, to: playbackRate, duration: transitionDuration)
    }

    func stopPlayback(playbackId: String, atTime: Double, fadeDuration: Double = 0.0) {
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.stop(at: time, fadeDuration: fadeDuration)
    }

    // MARK: Channels

    func setChannelVolume(channel: String, volume: Double) {
        channels[channel]?.volume = volume
    }

    func setChannelPan(channel: String, pan: Double) {
        channels[channel]?.pan = pan
    }

    func setChannelMuted(channel: String, muted: Bool) {
        channels[channel]?.muted = muted
    }

    func setMasterVolume(volume: Double) {
        mainMixer.volume = Float(volume)
    }    
}


// MARK: - Master engine stop/start methods for app states
extension AudioManager {
    
    public func stopEngine() {
        DispatchQueue.main.async {
            self.turnOffAllPlayers()
            self.stop()
        }
    }
    
    public func restartEngine() {
        DispatchQueue.main.async {
            do {
                try self.start()
            } catch {
                print(error)
            }
        }
    }
    
    private func turnOffAllPlayers() {
        channels.forEach({ channel in
            let value = channel.value
            value.stopAllPlayers()
        })
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
        return AVAudioTime(hostTime: 0).offset(seconds: self.browserTimeOffset + browserTime)
    }

    public func setBrowserTime(_ browserTime: Double) throws {
        do {
            let engineTime = try getMasterClockSeconds()
            self.browserTimeOffset = engineTime - browserTime
        } catch let error as AudioManagerError {
            throw error
        } catch {
            //Generic Error handling
        }
    }
}
