import AVFoundation

// For overview of how Cordova plugins are written in Swift:
// https://simonprickett.dev/writing-a-cordova-plugin-in-swift-3-for-ios/
//
// Examples of Swift plugins in the wild:
// https://github.com/cordova-rtc/cordova-plugin-iosrtc
// https://github.com/floydspace/cordova-plugin-geofence

@objc(CordovaAudioKitPlugin) class CordovaAudioKitPlugin: CDVPlugin {

    let manager = AudioManager()

    // MARK: Setup functions

    @objc(initialize:) func initialize(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let channelDefinitions = command.arguments[0] as! [[String: String]]

            do {
                // TODO: Initialize AudioKit and stuff
                try self.manager.setup(with: channelDefinitions)
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(loadSample:) func loadSample(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let sampleId = command.arguments[0] as! String
            let audioData = command.arguments[1] as! Data  // TODO: how to do we deal with optional vs required?

            do {
                let sample = try self.manager.loadSample(sampleId: sampleId, audioData: audioData)
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [
                        "sampleId": sample.id,
                        "duration": sample.duration,
                    ]
                )
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }
        })
    }

    // MARK: starting/stopping playback session

    @objc(gonnaPlay:) func gonnaPlay(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let browserTime = (command.arguments[0] as! Double)

            do {
                try self.manager.startEngine()
                try self.manager.setBrowserTime(browserTime)
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)

                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }
        })
    }

    @objc(gonnaStop:) func gonnaStop(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            do {
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {

            }

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    // MARK: Sample playback

    @objc(playSample:) func playSample(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let sampleId = command.arguments[0] as? String ?? ""
            let channel = command.arguments[1] as? String ?? ""
            let playbackId = command.arguments[2] as? String ?? ""
            let atTime = (command.arguments[3] as? Double ?? 0)
            let volume = (command.arguments[4] as? Double ?? 1.0)
            let offset = (command.arguments[5] as? Double ?? 0.0)
            let fadeInDuration = (command.arguments[6] as? Double ?? 0.0)
            let playbackRate = (command.arguments[7] as? Double ?? 1.0)
            // let playDuration = command.arguments[8] as? Double ?? 0  // not used

            do {
                let samplePlayback = try self.manager.playSample(
                    sampleId: sampleId,
                    channel: channel,
                    playbackId: playbackId,
                    atTime: atTime,
                    volume: volume,
                    offset: offset,
                    playbackRate: playbackRate,
                    fadeInDuration: fadeInDuration
                )
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [
                        "playbackId": samplePlayback.playbackId
                    ]
                )
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }
        })
    }

    // MARK: Playback manipulation

    @objc(setPlaybackVolume:) func setPlaybackVolume(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let playbackId = command.arguments[0] as? String ?? ""
            let atTime = (command.arguments[1] as? Double ?? 0)
            let volume = (command.arguments[2] as? Double ?? 0.5)
            let fadeDuration = (command.arguments[3] as? Double ?? 0.05)

            do {
                self.manager.setPlaybackVolume(
                    playbackId: playbackId,
                    atTime: atTime,
                    volume: volume,
                    fadeDuration: fadeDuration
                )
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK
                )
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }
        })
    }

    @objc(stopPlayback:) func stopPlayback(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let playbackId = command.arguments[0] as? String ?? ""
            let atTime = (command.arguments[1] as? Double ?? 0)
            let fadeDuration = (command.arguments[2] as? Double ?? 0.05)

            do {
                self.manager.stopPlayback(
                    playbackId: playbackId,
                    atTime: atTime,
                    fadeDuration: fadeDuration
                )
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK
                )
            } catch {
                // TODO: Set pluginResult error details if anything goes wrong
                // if (error) {
                //   pluginResult = CDVPluginResult(
                //     status: CDVCommandStatus_ERROR,
                //     messageAs: "err-code"
                //   )
                // }
            }
        })
    }

    // MARK: Channels

    @objc(setChannelVolume:) func setChannelVolume(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let channel = command.arguments[0] as? String ?? ""
            let volume = (command.arguments[1] as? Double ?? 0.5)

            self.manager.setChannelVolume(channel: channel, volume: volume)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(setChannelPan:) func setChannelPan(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let channel = command.arguments[0] as? String ?? ""
            let pan = (command.arguments[1] as? Double ?? 0.0)

            self.manager.setChannelPan(channel: channel, pan: pan)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(setChannelMuted:) func setChannelMuted(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let channel = command.arguments[0] as? String ?? ""
            let muted = command.arguments[1] as? Bool ?? false

            self.manager.setChannelMuted(channel: channel, muted: muted)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(setMasterVolume:) func setMasterVolume(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let volume = (command.arguments[0] as? Double ?? 0.5)

            self.manager.setMasterVolume(volume: volume)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc override func onReset() {
        // TODO: handle Cordova page reload as described here:
        // https://cordova.apache.org/docs/en/latest/guide/platforms/ios/plugin.html#plugin-initialization-and-lifetime
    }

    // @objc func onMemoryWarning() {
    // }

    // @objc func onAppTerminate() {
    // }
}
