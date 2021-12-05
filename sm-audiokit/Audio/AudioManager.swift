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

    init() {
        mainMixer = Mixer()
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

    func loadSample(sampleId: String, audioData: Data) -> Sample {
        let sample = SampleStorage.storeSample(sampleId: sampleId, audioData: audioData)
        sampleBank[sample.id] = sample
        return sample
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

    // MARK: Sample playback

    func playSample(sampleId: String,
                    channel: String,
                    playbackId: String,
                    atTime: Float,
                    volume: Float = 1.0,
                    offset: Float = 0.0,
                    playbackRate: Float = 1.0,
                    fadeInDuration: Float = 0.0) -> SamplePlayback? {
        // Grab sample and channel
        // TODO: this should probably throw if either isn't found
        let sample = self.sampleBank[sampleId]!
        let channel = self.channels[channel]!

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

    func browserTimeToAudioTime(_ browserTime: Float) -> AVAudioTime {
        // TODO: Implement browserTime conversion
        return AVAudioTime.now()
    }

    var browserTimeOffset = -1

    func setBrowserTime(_ browserTime: Float) {
        // TODO: calculate and store offset between browserTime and audio clock
    }

    // Some of Luke's old code that had to do with time stuff, in case it's useful (it probably isn't)
    /*
        self.browserTimeOffsetNs = DispatchTime.now().uptimeNanoseconds - UInt64(Int64(browserTime * 1000 * 1000 * 1000))

        let now = player.avAudioNode.lastRenderTime?.sampleTime

        let scheduledTime = AVAudioTime(hostTime: <#T##UInt64#>)
        player.schedule(at: atTime, completionCallbackType: .dataPlayedBack)
     */

    // Maximilian's code around time stuff
    /*

        //// Sample-frame accurate sync:
        ///

        //FIXME:- We will have a dedicated method for this, this is temporary.
        guard let masterPlayer = self.getAvailablePlayer() else {
            return
        }

        let avStartTime:

        let outputFormat = masterPlayer.player.avAudioNode.outputFormat(forBus: 0)
        guard let now = masterPlayer.player.avAudioNode.lastRenderTime?.sampleTime else {
            return
        }

        //FIXME:- Need to convert floats to AVFrameTime in order to do math properly.
        let startTime = AVAudioTime(sampleTime: ((now + startTime) +(delayTime * outputFormat.sampleRate)), atRate: outputFormat.sampleRate)

      */
  }
