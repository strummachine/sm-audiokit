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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AudioManager.shared.start()
            AudioManager.shared.setupChannels(["guitar", "drums", "test"])
            AudioManager.shared.loadTestPackage()
            availableSamples = AudioManager.shared.sampleBank
            NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: Notification.Name("PlayerCompletion"), object: nil)
        } catch let error as AudioManagerError {
            print(error.localizedDescription)
        } catch {
            // Generic Error handling
        }

        // Do any additional setup after loading the view.
//        AudioManager.shared.channels["guitar"]?.setPan(0.9)
//        AudioManager.shared.channels["drums"]?.setPan(0.1)
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        
        let shuffled = self.availableSamples.shuffled()
        let randomSample = shuffled[0].value
        // TODO: Using any channel other than "test" crashes the app. Why?
        // FIXME:
//            let channelName = randomSample.id.hasSuffix("--") ? "guitar" : "drums"
//            let channelName = "guitar"
        let channelName = "test"
        
        do {
            try AudioManager.shared.setBrowserTime(0.01)
            try AudioManager.shared.playSample(sampleId: randomSample.id, channel: channelName, playbackId: UUID().uuidString, atTime: 0.02)
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
            try AudioManager.shared.setBrowserTime(0.01)
            try AudioManager.shared.playSample(sampleId: testTone.id, channel: "test", playbackId: UUID().uuidString, atTime: 0.02)
            self.setLabel(with: "Playing sample: \(testTone.id)")
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
            try AudioManager.shared.setBrowserTime(0.01)
            do {
                let bpm = Float(187.0)
                for beat in 0...31 {
                    if beat % 4 == 0 {
                        try AudioManager.shared.playSample(sampleId: "kick", channel: "test", playbackId: ("kick"+String(beat)), atTime: 0.02 + (Float(beat) / bpm))
                    }
                    if beat % 4 == 2 {
                        try AudioManager.shared.playSample(sampleId: "snare", channel: "test", playbackId: ("snare"+String(beat)), atTime: 0.02 + (Float(beat) / bpm))
                    }
                    if beat % 8 != 7 {
                        try AudioManager.shared.playSample(sampleId: "hat-closed", channel: "test", playbackId: ("hat"+String(beat)), atTime: 0.02 + (Float(beat) / bpm))
                    } else {
                        try AudioManager.shared.playSample(sampleId: "hat-open", channel: "test", playbackId: "hat-open-pb", atTime: 0.02 + (Float(beat) / bpm))
                        AudioManager.shared.setPlaybackVolume(playbackId: "hat-open-pb", atTime: 0.2 + (Float(beat + 1) / bpm), volume: 0.0, fadeDuration: 0.05)
                    }
                }
            } catch let error as AudioManagerError {
                print(error.description)
            } catch {
                //Generic Error Handeling
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

