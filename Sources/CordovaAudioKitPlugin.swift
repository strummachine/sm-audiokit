import AVFoundation

// For overview of how Cordova plugins are written in Swift:
// https://simonprickett.dev/writing-a-cordova-plugin-in-swift-3-for-ios/

// Example of a Swift plugin in the wild:
// https://github.com/floydspace/cordova-plugin-geofence/blob/master/src/ios/GeofencePlugin.swift

// @interface CDVInvokedUrlCommand : NSObject {
//   NSString* _callbackId;
//   NSString* _className;
//   NSString* _methodName;
//   NSArray* _arguments;
// }

@objc(CordovaAudioKitPlugin) class CordovaAudioKitPlugin : CDVPlugin {

    var manager: AudioManager?

    // MARK: Setup functions

    @objc(initialize:) func initialize(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                // TODO: Initialize AudioKit and stuff
                // try self.manager?.start()
                self.manager = AudioManager()
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
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let sampleId = command.arguments[0] as! String
        let audioData = command.arguments[1] as! Data  // TODO: how to do we deal with optional vs required?

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                guard let sample = try self.manager?.loadSample(sampleId: sampleId, audioData: audioData) else { return }
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [
                        "sampleId": sample.id,
                        "duration": sample.duration
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

    @objc(setupChannels:) func setupChannels(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let channelNames = command.arguments[0] as! Array<String>

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                for channel in channelNames {
                    self.manager?.createChannel(id: channel)
                }

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

    // MARK: starting/stopping playback session

    @objc(gonnaPlay:) func gonnaPlay(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let browserTime = (command.arguments[0] as! Double)

        do {
            try self.manager?.start()
            try self.manager?.setBrowserTime(browserTime)
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

        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(gonnaStop:) func gonnaStop(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)

        do {
            try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {

        }

        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }

    // MARK: Sample playback

    @objc(playSample:) func playSample(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let sampleId = command.arguments[0] as? String ?? ""
        let channel = command.arguments[1] as? String ?? ""
        let playbackId = command.arguments[2] as? String ?? ""
        let atTime = (command.arguments[3] as? Double ?? 0)
        let volume = (command.arguments[4] as? Double ?? 0)
        let offset = (command.arguments[5] as? Double ?? 0)
        let playbackRate = (command.arguments[6] as? Double ?? 1)
        let fadeInDuration = (command.arguments[7] as? Double ?? 0)
        // let playDuration = command.arguments[8] as? Double ?? 0  // not used

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                guard let samplePlayback = try self.manager?.playSample(
                    sampleId: sampleId,
                    channel: channel,
                    playbackId: playbackId,
                    atTime: atTime,
                    volume: volume,
                    offset: offset,
                    playbackRate: playbackRate,
                    fadeInDuration: fadeInDuration
                ) else { return }
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
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let playbackId = command.arguments[0] as? String ?? ""
        let atTime = (command.arguments[1] as? Double ?? 0)
        let volume = (command.arguments[2] as? Double ?? 0)
        let fadeDuration = (command.arguments[3] as? Double ?? 0)

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                self.manager?.setPlaybackVolume(
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
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)

        let playbackId = command.arguments[0] as? String ?? ""
        let atTime = (command.arguments[1] as? Double ?? 0)
        let fadeDuration = (command.arguments[2] as? Double ?? 0)

        DispatchQueue.main.async(execute: {
            defer {
                DispatchQueue.main.async(execute: {
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                })
            }

            do {
                self.manager?.stopPlayback(
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
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

        let channel = command.arguments[0] as? String ?? ""
        let volume = (command.arguments[1] as? Double ?? 0)

        self.manager?.setChannelVolume(channel: channel, volume: volume)

        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
    }

    @objc(setChannelPan:) func setChannelPan(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

        let channel = command.arguments[0] as? String ?? ""
        let pan = (command.arguments[1] as? Double ?? 0)

        self.manager?.setChannelPan(channel: channel, pan: pan)

        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
    }

    @objc(setChannelMuted:) func setChannelMuted(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

        let channel = command.arguments[0] as? String ?? ""
        let muted = command.arguments[1] as? Bool ?? false

        self.manager?.setChannelMuted(channel: channel, muted: muted)

        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
    }

    @objc(setMasterVolume:) func setMasterVolume(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

        let volume = (command.arguments[0] as? Double ?? 0)

        self.manager?.setMasterVolume(volume: volume)

        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
    }


    // @objc func onReset() {
    //   // TODO: handle Cordova page reload as described here:
    //   // https://cordova.apache.org/docs/en/latest/guide/platforms/ios/plugin.html#plugin-initialization-and-lifetime
    // }

    // @objc func onMemoryWarning() {
    // }

    // @objc func onAppTerminate() {
    // }
}
