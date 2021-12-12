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
    let mainMixer: Mixer = Mixer(volume: 1.0, name: "master")

    var channels: [String: Channel] = [:]
    var playbacks: [String: SamplePlayback] = [:]
    var playerPool = SamplePlayerPool()

    var browserTimeOffset: Double = 0.0
    
    internal var notifier = NotificationCenter.default
    
    init() {}

    // MARK: Setup and Teardown

    var isSetup: Bool {
        get { self.channels.count > 0 }
    }

    public func setup(channelIds: [String], polyphonyLimit: Int) throws {
        guard !isSetup else { return }
        self.engine.rebuildGraph()
        do {
            try setAVAudioSession(asActive: false)
            for id in channelIds {
                self.channels[id] = Channel(id: id, mainMixer: self.mainMixer)
            }
            self.playerPool.createPlayers(count: polyphonyLimit)
            registerForNotifications()
            engine.output = mainMixer
        } catch {
            throw error
        }
    }
    
    public func teardown() {
        DispatchQueue.main.async {
            print("Tearing down AudioManager")
            self.playerPool.stopAllPlayers()
            self.playerPool.removeAllPlayers()
            self.channels.removeAll()

            self.engine.stop()
            do {
                try self.setAVAudioSession(asActive: false)
            } catch {
                print("Error: Cannot set avaudiosession as false:\(error)")
            }

            self.deregisterNotificationObservers()
        }
    }
    
    public func setAVAudioSession(asActive: Bool) throws {
        #if os(iOS)
        if asActive {
            do {
                Settings.bufferLength = .veryLong
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("ERROR: Can't set avaudiosession:\(error)")
                throw error
            }
        }
        else {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                throw error
            }
        }
        #endif
    }

    // MARK: Master engine stop/start methods for app states

    public func startEngine() throws {
        // TODO: we could add some checks to make sure channels are setup etc...
        do {
            try self.engine.start()
            print("Started Audio Engine")
            try self.setAVAudioSession(asActive: true)
        } catch {
            throw AudioManagerError.audioEngineCannotStart(error: error)
        }
    }
    
    public func stopEngine() {
        print("Stopping Engine")
        // TODO: Make actually smooth fade out by ramping channel faders?
        self.playerPool.stopAllPlayers()
        engine.stop()
        do {
            try self.setAVAudioSession(asActive: false)
        } catch {
            print("Error: Cannot set avaudiosession as false:\(error)")
        }
    }
    
    public func restartEngine() {
        DispatchQueue.main.async {
            do {
                try self.setAVAudioSession(asActive: true)
                do {
                    try self.engine.start()
                    print("Started Audio Engine")
                } catch {
                    throw AudioManagerError.audioEngineCannotStart(error: error)
                }
            } catch {
                print(error)
            }
        }
    }

    // MARK: Sample Playback

    public func playSample(sampleId: String,
                           channel: String,
                           playbackId: String,
                           atTime: Double,
                           volume: Double = 1.0,
                           offset: Double = 0.0,
                           playbackRate: Double = 1.0,
                           fadeInDuration: Double = 0.0
    ) throws -> SamplePlayback {
        guard self.engine.avEngine.isRunning else {
            throw AudioManagerError.audioEngineNotRunning
        }
        guard let sample = SampleStorage.sampleBank[sampleId] else {
            throw AudioManagerError.cannotFindSample(sampleId: sampleId)
        }
        guard let channel = self.channels[channel] else {
            throw AudioManagerError.cannotFindChannel(channel: channel)
        }

        let startTime = browserTimeToAudioTime(atTime)

        do {
            let player = self.playerPool.getPlayer(forSample: sample)
            let playback = try player.schedulePlayback(
                sample: sample,
                channel: channel,
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
        guard self.engine.avEngine.isRunning else { return }
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.fade(at: time, to: volume, duration: fadeDuration)
    }

    // This one doesn't need to be implemented for v1
    func setPlaybackRate(playbackId: String, atTime: Double, playbackRate: Double, transitionDuration: Double) {
        guard self.engine.avEngine.isRunning else { return }
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.changePlaybackRate(at: time, to: playbackRate, duration: transitionDuration)
    }

    func stopPlayback(playbackId: String, atTime: Double, fadeDuration: Double = 0.0) {
        guard self.engine.avEngine.isRunning else { return }
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.stop(at: time, fadeDuration: fadeDuration)
    }

    // MARK: Channels

    public func setChannelVolume(channel: String, volume: Double) {
        channels[channel]?.volume = volume
    }

    public func setChannelPan(channel: String, pan: Double) {
        channels[channel]?.pan = pan
    }

    public func setChannelMuted(channel: String, muted: Bool) {
        channels[channel]?.muted = muted
    }

    public func setMasterVolume(volume: Double) {
        mainMixer.volume = Float(volume)
    }

    // MARK: Audio Clock Timing Methods

    public func browserTimeToAudioTime(_ browserTime: Double) -> AVAudioTime {
        return AVAudioTime(hostTime: 0).offset(seconds: self.browserTimeOffset + browserTime)
    }

    public func setBrowserTime(_ browserTime: Double) throws {
        let systemTime = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        self.browserTimeOffset = systemTime - browserTime
    }
}
