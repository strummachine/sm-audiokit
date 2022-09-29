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
    let ultimateMixer: Mixer = Mixer(volume: 1.0, name: "ultimate")
    let timePitch: TimePitch

    var channels: [String: Channel] = [:]
    var playbacks: [String: SamplePlayback] = [:]

    var browserTimeOffset: Double = 0.0
    
    internal var notifier = NotificationCenter.default
    
    init() {
        self.timePitch = TimePitch(self.mainMixer)
        self.timePitch.bypass()
        self.ultimateMixer.addInput(self.timePitch)
    }

    // MARK: Setup and Teardown

    var isSetup: Bool {
        get { self.channels.count > 0 }
    }

    internal private(set) var acceptingCommands = false

    public func setup(channels: [ChannelDefinition]) throws {
        guard !isSetup else { return }
        self.engine.rebuildGraph()
        do {
            try setAVAudioSession(asActive: false)
            for channel in channels {
                self.channels[channel.id] = Channel(
                    id: channel.id,
                    polyphonyLimit: channel.polyphonyLimit,
                    mainMixer: self.mainMixer
                )
            }
            registerForNotifications()
            engine.output = self.ultimateMixer
        } catch {
            throw error
        }
    }
    
    public func teardown() {
        DispatchQueue.main.async {
            print("Tearing down AudioManager")
            self.acceptingCommands = false
            for channel in self.channels.values {
                channel.playerPool.stopAllPlayers()
                channel.mixer.removeAllInputs()
            }
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
            try self.setAVAudioSession(asActive: true)
            try self.engine.start()
            print("Started Audio Engine")
            self.acceptingCommands = true
        } catch {
            throw AudioManagerError.audioEngineCannotStart(error: error)
        }
    }
    
    public func stopEngine() {
        print("Stopping Engine")
        self.acceptingCommands = false
        // TODO: Make actually smooth fade out by ramping channel faders?
        for channel in self.channels.values {
            channel.playerPool.stopAllPlayers()
        }
        engine.stop()
        do {
            try self.setAVAudioSession(asActive: false)
        } catch {
            print("Error: Cannot set avaudiosession as false:\(error)")
        }
    }

    public func stopEngineDueToInterruption() {
        print("Stopping engine due to an interruption")
        self.acceptingCommands = false
        for channel in self.channels.values {
            channel.playerPool.stopAllPlayers()
        }
        engine.stop()
    }
    
    public func restartEngine() {
        DispatchQueue.main.async {
            do {
                try self.setAVAudioSession(asActive: true)
                do {
                    try self.engine.start()
                    print("Started Audio Engine")
                    self.acceptingCommands = true
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
        guard self.acceptingCommands else {
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
            let player = channel.playerPool.getPlayer(forSample: sample)
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
        guard self.acceptingCommands else { return }
        let time = browserTimeToAudioTime(atTime)
        playbacks[playbackId]?.fade(at: time, to: volume, duration: fadeDuration)
    }

    func stopPlayback(playbackId: String, atTime: Double, fadeDuration: Double = 0.0) {
        guard self.acceptingCommands else { return }
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

    public func setMasterPitch(cents: Double) {
        timePitch.pitch = Float(cents)
        if cents == 0.0 {
            self.timePitch.bypass()
        } else {
            self.timePitch.start()
        }
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
