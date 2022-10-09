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

            do {
                let channelIds = command.arguments[0] as! [String]
                let channelPolyphonyLimits = command.arguments[1] as! [Int]

                var channelDefs: [ChannelDefinition] = []
                for i in 0..<channelIds.count {
                    let def = ChannelDefinition(id: channelIds[i], polyphonyLimit: channelPolyphonyLimits[i])
                    channelDefs.append(def)
                }

                try self.manager.setup(channels: channelDefs)
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            } catch {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: "\(error)"
                )
            }
        })
    }

    @objc(getStoredSampleList:) func getStoredSampleList(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            SampleStorage.getStoredSampleList(completion: { result in
                switch result {
                case .success(let storedSamples):
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: storedSamples.map({ ss in
                            return [
                                "sampleId": ss.sampleId,
                                "packageId": ss.packageId
                            ]
                        })
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                case .failure(let error):
                    print(error)
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: error.description  // TODO: what format is this and how should it be passed?
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            })
        })
    }

    @objc(storeSample:) func storeSample(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            let packageId = command.arguments[0] as! String
            let sampleId = command.arguments[1] as! String
            let audioData = command.arguments[2] as! Data  // TODO: how to do we deal with optional vs required?

            let pns = PackageIdAndSampleId(packageId: packageId, sampleId: sampleId)

            SampleStorage.storeSample(packageIdAndSampleId: pns, audioData: audioData, completion: { result in
                switch result {
                case .success(let sample):
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [
                            "sampleId": sample.id,
                            "duration": sample.duration
                        ]
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                case .failure(let error):
                    print(error)
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: error.description // TODO: what format is this and how should it be passed?
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            })
        })
    }

    @objc(loadSamplesFromDisk:) func loadSamplesFromDisk(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            let packageAndSampleDict = command.arguments[0] as? [[String: String]] ?? []

            let packageIdsAndSampleIds = packageAndSampleDict.map({ ps in
                PackageIdAndSampleId(packageId: ps["packageId"]!, sampleId: ps["sampleId"]!)
            })

            SampleStorage.loadSamplesFromDisk(packageIdsAndSampleIds, completion: { result in
                switch result {
                case .success(let samples):
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: samples.map({ sample in
                            return [
                                "sampleId": sample.id,
                                "duration": sample.duration
                            ]
                        })
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                case .failure(let error):
                    print(error)
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: error.description
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            })
        })
    }

    @objc(deleteSamples:) func deleteSamples(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            let packageAndSampleDict = command.arguments[0] as? [[String: String]] ?? []

            let packageIdsAndSampleIds = packageAndSampleDict.map({ ps in
                PackageIdAndSampleId(packageId: ps["packageId"]!, sampleId: ps["sampleId"]!)
            })

            SampleStorage.deleteSamples(packageIdsAndSampleIds, completion: { result in
                switch result {
                case .success(let message):
                    print(message)
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: message
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                case .failure(let error):
                    print(error)
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: error.description
                    )
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            })
        })
    }

    // MARK: starting/stopping playback session

    @objc(startEngine:) func startEngine(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let browserTime = (command.arguments[0] as! Double)

            do {
                try self.manager.setBrowserTime(browserTime)
                try self.manager.startEngine()
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            } catch {
                print("ERROR in startEngine")
                print(error)
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: error.localizedDescription
                )
            }
        })
    }

    @objc(stopEngine:) func stopEngine(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            self.manager.stopEngine()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    // MARK: Sample playback

    @objc(sendBatchedCommands:) func sendBatchedCommands(command: CDVInvokedUrlCommand) {
        guard self.manager.acceptingCommands else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Audio engine not running"
            )
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            var results = []
            for cmdNameAndArgs in (command.arguments[0] as! [[Any]]) {
                let cmdName = cmdNameAndArgs[0] as? String ?? ""
                let args = cmdNameAndArgs[1] as? [Any] ?? []

                switch cmdName {
                case "playSample":
                    let sampleId = args[0] as? String ?? ""
                    let channel = args[1] as? String ?? ""
                    let playbackId = args[2] as? String ?? ""
                    let atTime = (args[3] as? Double ?? 0)
                    let volume = (args[4] as? Double ?? 1.0)
                    let offset = (args[5] as? Double ?? 0.0)
                    let fadeInDuration = (args[6] as? Double ?? 0.0)

                    do {
                        let samplePlayback = try self.manager.playSample(
                            sampleId: sampleId,
                            channel: channel,
                            playbackId: playbackId,
                            atTime: atTime,
                            volume: volume,
                            offset: offset,
                            fadeInDuration: fadeInDuration
                        )
                        results.append([ "playbackId": samplePlayback != nil ? samplePlayback?.playbackId : UUID().uuidString ])
                    } catch {
                        results.append(["error": error.localizedDescription])
                    }

                case "setPlaybackVolume":
                    let playbackId = args[0] as? String ?? ""
                    let atTime = (args[1] as? Double ?? 0)
                    let volume = (args[2] as? Double ?? 0.5)
                    let fadeDuration = (args[3] as? Double ?? 0.05)

                    self.manager.setPlaybackVolume(
                        playbackId: playbackId,
                        atTime: atTime,
                        volume: volume,
                        fadeDuration: fadeDuration
                    )
                    results.append([:])

                case "stopPlayback":
                    let playbackId = args[0] as? String ?? ""
                    let atTime = (args[1] as? Double ?? 0)
                    let fadeDuration = (args[2] as? Double ?? 0.05)

                    self.manager.stopPlayback(
                        playbackId: playbackId,
                        atTime: atTime,
                        fadeDuration: fadeDuration
                    )
                    results.append([:])

                default:
                    results.append([:])
                }
            }

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: results
            )
        })
    }

    // MARK: Playback manipulation

    @objc(playSample:) func playSample(command: CDVInvokedUrlCommand) {
        guard self.manager.acceptingCommands else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Audio engine not running"
            )
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }

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

            do {
                let samplePlayback = try self.manager.playSample(
                    sampleId: sampleId,
                    channel: channel,
                    playbackId: playbackId,
                    atTime: atTime,
                    volume: volume,
                    offset: offset,
                    fadeInDuration: fadeInDuration
                )
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [
                        "playbackId": samplePlayback != nil ? samplePlayback?.playbackId : UUID().uuidString
                    ]
                )
            } catch {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: "Sample playback failed: \(error)"
                )
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

            self.manager.setPlaybackVolume(
                playbackId: playbackId,
                atTime: atTime,
                volume: volume,
                fadeDuration: fadeDuration
            )
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(stopPlayback:) func stopPlayback(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let playbackId = command.arguments[0] as? String ?? ""
            let atTime = (command.arguments[1] as? Double ?? 0)
            let fadeDuration = (command.arguments[2] as? Double ?? 0.05)

            self.manager.stopPlayback(
                playbackId: playbackId,
                atTime: atTime,
                fadeDuration: fadeDuration
            )
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
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

            let volume = (command.arguments[0] as? Double ?? 1.0)

            self.manager.setMasterVolume(volume: volume)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc(setMasterPitch:) func setMasterPitch(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async(execute: {
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
            defer { self.commandDelegate!.send(pluginResult, callbackId: command.callbackId) }

            let cents = (command.arguments[0] as? Double ?? 0.0)

            self.manager.setMasterPitch(cents: cents)

            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        })
    }

    @objc override func onReset() {
        self.manager.teardown()
    }

    // @objc func onMemoryWarning() {
    // }

    // @objc func onAppTerminate() {
    // }
}
