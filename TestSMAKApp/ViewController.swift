//
//  ViewController.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/18/21.
//

import UIKit
import AVFoundation
import CryptoKit
class ViewController: UIViewController {

    @IBOutlet weak var scheduleSampleTextField: UITextField!
    
    @IBOutlet weak var playingSampleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLabel(with: "Loading")
        SampleStorage.deleteAllStoredSamples(completion: { result in
            switch result {
                case .success(let message):
                    print(message)
                case .failure(let error):
                    print(error)
            }
        })
        // Do any additional setup after loading the view.
        //        AudioManager.shared.channels["guitar"]?.setPan(0.9)
        //        AudioManager.shared.channels["drums"]?.setPan(0.1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            let testPackageUrl = try AudioPackageExtractor.getTestPackageUrl()
            AudioPackageExtractor.load(url: testPackageUrl, completion: { result in
                switch result {
                case .success(let samples):
                    self.setLabel(with: "Ready")
                    
                    SampleStorage.getStoredSampleList(completion: { result in
                        switch result {
                        case .success(let sampleList):
                            print("Samples loaded from test package:")
                            print(sampleList.map({" · \($0.packageId) / \($0.sampleId)"}).sorted().joined(separator: "\n"))
                        case .failure(let error):
                            print(error)
                        }
                    })
                    
                case .failure(let error):
                    print(error)
                }
            })

            let channels: [ChannelDefinition] = [
                ChannelDefinition(id: "guitar", polyphonyLimit: 32),
                ChannelDefinition(id: "drums", polyphonyLimit: 16),
                ChannelDefinition(id: "test", polyphonyLimit: 4),
            ]

            try AudioManager.shared.setup(channels: channels)
            try AudioManager.shared.startEngine()
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: Notification.Name("PlayerCompletion"), object: nil)
        } catch let error as AudioManagerError {
            print(error.localizedDescription)
        } catch {
            print(error)
        }

    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        
        let shuffled = SampleStorage.sampleBank.shuffled()
        let randomSample = shuffled[0].value
        let channelName = randomSample.id.hasSuffix("--") ? "guitar" : "drums"

        do {
            try AudioManager.shared.setBrowserTime(2.0)
            try AudioManager.shared.playSample(sampleId: randomSample.id, channel: channelName, playbackId: UUID().uuidString, atTime: 2.3)
            self.setLabel(with: "Playing Sample: \(randomSample.id)")
        } catch let error as AudioManagerError{
            print(error.description)
        } catch {
            // Generic Error handling
        }
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
        guard let testTone = SampleStorage.sampleBank["test-tone"] else { return }
        do {
            let delay = 0.5
            try AudioManager.shared.setBrowserTime(5.0)
            let pb = try AudioManager.shared.playSample(sampleId: testTone.id, channel: "test", playbackId: UUID().uuidString, atTime: 5.0 + delay, fadeInDuration: 0.20)
            AudioManager.shared.setPlaybackVolume(playbackId: pb.playbackId, atTime: 5.0 + delay + 0.5, volume: 0.0, fadeDuration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(Int(delay * 1000)), execute: {
                self.setLabel(with: "Playing/fading sample: \(testTone.id)")
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(Int(delay * 1000 + 500)), execute: {
                self.setLabel(with: "Ready")
            })
        } catch let error as AudioManagerError {
            print(error.description)
        } catch {
            // Generic Error handling
        }
    }
    
    // This button has been commandeered to play a bunch of scheduled samples
    @IBAction func tappedScheduledSample(_ sender: Any) {
        self.setLabel(with: "Rocking out...")
        do {
            try AudioManager.shared.setBrowserTime(-1.01)
            var iteration = 0
            let bpm = Double(300.0)
            let beatDuration = 60.0 / bpm
            let iterationDuration = 8 * beatDuration
            let drumLoop = {
                print("Starting iteration \(iteration)")
                do {
                    for beat in 0...7 {
                        let timeOfBeat = 0.02 + Double(iteration) * iterationDuration + beatDuration * Double(beat)
                        let timeOfNextBeat = timeOfBeat + beatDuration
                        if beat % 4 == 0 {
                            try AudioManager.shared.playSample(sampleId: "kick", channel: "guitar", playbackId: ("kick"+String(beat)), atTime: timeOfBeat)
                        }
                        if beat % 4 == 2 {
                            try AudioManager.shared.playSample(sampleId: "snare", channel: "test", playbackId: ("snare"+String(beat)), atTime: timeOfBeat)
                        }
                        if beat % 8 != 7 {
                            try AudioManager.shared.playSample(sampleId: "hat-closed", channel: "drums", playbackId: ("hat"+String(beat)), atTime: timeOfBeat)
                        } else {
                            let pb = try AudioManager.shared.playSample(sampleId: "hat-open", channel: "drums", playbackId: "hat-open-pb", atTime: timeOfBeat)
                            AudioManager.shared.setPlaybackVolume(playbackId: pb.playbackId, atTime: timeOfNextBeat, volume: 0.0, fadeDuration: 0.05)
                        }
                    }
                } catch let error as AudioManagerError {
                    print(error.description)
                } catch {
                    //Generic Error Handeling
                }
                iteration += 1
            }
            for iterationBeingPlanned in 0...200 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(Int(1000 * Double(iterationBeingPlanned) * iterationDuration)), execute: drumLoop)
            }
        } catch let error as AudioManagerError {
            print(error.description)
        } catch {
            //Generic Error Handeling
        }
    }
    
    @objc func updateLabel() {
        DispatchQueue.main.async {
            self.playingSampleLabel.text = "Ready"
        }
    }
    
    func setLabel(with string:String) {
        DispatchQueue.main.async {
            self.playingSampleLabel.text = string
        }
    }

}

