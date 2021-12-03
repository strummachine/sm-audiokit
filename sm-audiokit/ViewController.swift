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
        availableSamples = AudioManager.shared.sampleBank
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: Notification.Name("PlayerCompletion"), object: nil)
        // Do any additional setup after loading the view.
        AudioManager.shared.channels["guitar"]?.setPan(0.9)
        AudioManager.shared.channels["drums"]?.setPan(-0.9)
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        DispatchQueue.main.async {
          let shuffled = self.availableSamples.shuffled()
          let randomFile = shuffled[0].value
            do {
                self.playingSampleLabel.text = "Playing sample:\(randomFile.id)"
              let channelName = randomFile.id.hasSuffix("--") ? "guitar" : "drums"
                AudioManager.shared.playSample(sampleId: randomFile.id, channel: channelName, playbackId: "asdf", atTime: 0.0)
            } catch {
                print("Error: Can't load file:\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
        guard let testTone = self.availableSamples["test-tone"] else { return }
        
        do {
            self.playingSampleLabel.text = "Playing sample:\(testTone.id)"
            AudioManager.shared.playSample(sampleId: testTone.id, channel: "test", playbackId: "asdf", atTime: 0.0)
        } catch {
            print("Error: Can't load file:\(error.localizedDescription)")
        }
    }
    
    // This button commandeered to play a bunch of scheduled samples
    @IBAction func tappedScheduledSample(_ sender: Any) {
        self.playingSampleLabel.text = "Rocking out..."
        for beat in 0...31 {
            if beat % 4 == 0 {
                AudioManager.shared.playSample(sampleId: "kick", channel: "drums", playbackId: ("kick"+String(beat)), atTime: (Float(beat) * 0.2))
            }
            if beat % 4 == 2 {
                AudioManager.shared.playSample(sampleId: "snare", channel: "drums", playbackId: ("snare"+String(beat)), atTime: (Float(beat) * 0.2))
            }
            if beat % 8 != 7 {
                AudioManager.shared.playSample(sampleId: "hat-closed", channel: "drums", playbackId: ("hat"+String(beat)), atTime: (Float(beat) * 0.2))
            } else {
                AudioManager.shared.playSample(sampleId: "hat-open", channel: "drums", playbackId: "hat-open-pb", atTime: (Float(beat) * 0.2))
                AudioManager.shared.stopPlayback(playbackId: "hat-open-pb", atTime: (Float(beat + 1) * 0.2))
            }
        }
    }
    
    @objc func updateLabel() {
        DispatchQueue.main.async {
            self.playingSampleLabel.text = "Ready"
        }
    }
}

