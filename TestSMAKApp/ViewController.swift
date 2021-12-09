//
//  ViewController.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/18/21.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var scheduleSampleTextField: UITextField!
    
    @IBOutlet weak var playingSampleLabel: UILabel!
    
    var availableSamples: [String: Sample] = [:]

    var audioManager = AudioManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            audioManager.createChannel(id: "guitar", polyphonyLimit: 20)
            audioManager.createChannel(id: "drums", polyphonyLimit: 40)
            audioManager.createChannel(id: "test", polyphonyLimit: 20)
            audioManager.loadTestPackage()
            try audioManager.start()
            self.setLabel(with: "Ready")
            availableSamples = audioManager.sampleBank
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: Notification.Name("PlayerCompletion"), object: nil)
        } catch let error as AudioManagerError {
            print(error.localizedDescription)
        } catch {
            // Generic Error handling
        }

        // Do any additional setup after loading the view.
        //        audioManager.channels["guitar"]?.setPan(0.9)
        //        audioManager.channels["drums"]?.setPan(0.1)
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        
        let shuffled = self.availableSamples.shuffled()
        let randomSample = shuffled[0].value
        let channelName = randomSample.id.hasSuffix("--") ? "guitar" : "drums"

        do {
            try audioManager.setBrowserTime(2.0)
            try audioManager.playSample(sampleId: randomSample.id, channel: channelName, playbackId: UUID().uuidString, atTime: 2.3)
            self.setLabel(with: "Playing Sample: \(randomSample.id)")
        } catch let error as AudioManagerError{
            print(error.description)
        } catch {
            // Generic Error handling
        }
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
        guard let testTone = self.availableSamples["test-tone"] else { return }
        do {
            let delay = 0.5
            try audioManager.setBrowserTime(5.0)
            let pb = try audioManager.playSample(sampleId: testTone.id, channel: "test", playbackId: UUID().uuidString, atTime: 5.0 + delay)
            audioManager.setPlaybackVolume(playbackId: pb.playbackId, atTime: 5.0 + delay + 0.5, volume: 0.0, fadeDuration: 0.5)
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
            try audioManager.setBrowserTime(-1.01)
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
                            try self.audioManager.playSample(sampleId: "kick", channel: "guitar", playbackId: ("kick"+String(beat)), atTime: timeOfBeat)
                        }
                        if beat % 4 == 2 {
                            try self.audioManager.playSample(sampleId: "snare", channel: "test", playbackId: ("snare"+String(beat)), atTime: timeOfBeat)
                        }
                        if beat % 8 != 7 {
                            try self.audioManager.playSample(sampleId: "hat-closed", channel: "drums", playbackId: ("hat"+String(beat)), atTime: timeOfBeat)
                        } else {
                            let pb = try self.audioManager.playSample(sampleId: "hat-open", channel: "drums", playbackId: "hat-open-pb", atTime: timeOfBeat)
                            self.audioManager.setPlaybackVolume(playbackId: pb.playbackId, atTime: timeOfNextBeat, volume: 0.0, fadeDuration: 0.05)
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

