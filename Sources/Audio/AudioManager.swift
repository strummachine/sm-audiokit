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
    var sampleBank: [String: Sample] = [:]

    var browserTimeOffset: Double = 0.0
    
    internal var notifier = NotificationCenter.default
    
    public var applicationState : ApplicationState = .foreground
    
    init() {
        
    }

    private func start() throws {
        do {
            try engine.start()
            print("Started Audio Engine")
        } catch {
            throw AudioManagerError.audioEngineCannotStart(error: error)
        }
    }
    private func stop() {
        engine.stop()
        do {
            try self.setAVAudioSession(asActive: false)
        } catch {
            print("Error: Cannot set avaudiosession as false:\(error)")
        }
    }
}

// MARK: - Setup methods
extension AudioManager {
    public func setup(with channels:[[String: String]]) throws {
        do {
            try setAVAudioSession(asActive: true)
            for channel in channels {
                guard let id = channel[ChannelDictConstants.id.rawValue] else {
                    throw AudioManagerError.cannotFindChannelId(channelId: ChannelDictConstants.id.rawValue)
                }
                ////The strategy here is to unwrap the polyphony limit, however if one is not
                /// provided, we have the default amount of 16. We don't want to throw
                /// an error if a limit is not provided.
                let polyLimitString = channel[ChannelDictConstants.polyphonyLimit.rawValue] ?? "16"
                let polyphonyLimit = Int(polyLimitString)
                createChannel(id: id, polyphonyLimit: polyphonyLimit ?? 16)
            }
            registerForNotifications()
            engine.output = mainMixer
        } catch {
            throw error
        }
    }
    public func teardown() {
        DispatchQueue.main.async {
            self.turnOffAllPlayers()
            self.removeChannels()
            self.stop()
        }
    }
    
    public func setAVAudioSession(asActive: Bool) throws {
        #if os(iOS)
        if asActive {
            do {
                Settings.bufferLength = .short
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("ERROR: Can't set avaudiosession:\(error)")
                throw error
            }
        }
        else {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                throw error
            }
        }
        #endif
    }
}


// MARK: - Master engine stop/start methods for app states
extension AudioManager {
    public func startEngine() throws {
        // TODO: we could add some checks to make sure channels are setup etc...
        do {
            try start()
        } catch {
            throw error
        }
    }
    
    public func stopEngine() {
        turnOffAllPlayers()
        stop()
    }
    
    public func restartEngine() {
        DispatchQueue.main.async {
            do {
                try self.setAVAudioSession(asActive: true)
                try self.start()
            } catch {
                print(error)
            }
        }
    }
    
    // TODO: - Make actually smooth fade out
    private func turnOffAllPlayers() {
        channels.forEach({ channel in
            let value = channel.value
            let fader = Fader(value.mixer, gain: value.mixer.volume)
            self.mainMixer.addInput(fader)
            fader.start()
            fader.$leftGain.ramp(to: 0.0, duration: 0.25)
            fader.$rightGain.ramp(to: 0.0, duration: 0.25)
            value.stopAllPlayers()
        })
    }
    
}

// MARK: - Sample Methods
extension AudioManager {
    public func loadSample(sampleId: String, audioData: Data) throws -> Sample {
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

    
    public func playSample(sampleId: String,
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
}

// MARK: - Playback manipulation
extension AudioManager {
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
}

// MARK: - Channels
extension AudioManager {
    private func createChannel(id: String, polyphonyLimit: Int) {
        self.channels[id] = Channel(id: id, polyphonyLimit: polyphonyLimit, mainMixer: self.mainMixer)
    }
    private func removeChannels() {
        self.channels.forEach { dict in
            let channel = dict.value
            channel.tearDownPlayers()
        }
        self.channels.removeAll()
    }
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

// MARK: - Audio Package Methods
extension AudioManager {
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
}

enum ApplicationState: String {
    case foreground = "Foreground"
    case resignActive = "resignActive"
    case background = "background"
}

//Essentially a swifty way of doing string consts
enum ChannelDictConstants: String {
    case id = "id"
    case polyphonyLimit = "polyphonyLimit"
}
