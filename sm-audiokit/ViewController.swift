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
    
    var availableSamples: [Sample] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let samples = AudioPackageExtractor.extractAudioPackage() else {
            fatalError("Can't unwrap audio packages")
        }
        availableSamples = samples
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: Notification.Name("PlayerCompletion"), object: nil)
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        DispatchQueue.main.async {
            let shuffled = self.availableSamples.shuffled()
            let randomFile = shuffled[0]
            do {
                let file = try AVAudioFile(forReading: randomFile.url)
                self.playingSampleLabel.text = "Playing sample:\(randomFile.id)"
                // Fade Duration: How long the fade lasts
                // Fade Start: Duration of file - Fade start = When fade starts after file is playing
                AudioManager.shared.loadPlayer(with: file, fadeDuration: 0.25, fadeStart: 500)
            } catch {
                print("Error: Can't load file:\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
        let testToneArray = self.availableSamples.filter({$0.id == "test-tone"})
        let testTone = testToneArray[0]
        
        do {
            let file = try AVAudioFile(forReading: testTone.url)
            self.playingSampleLabel.text = "Playing sample:\(testTone.id)"
            // Fade Duration: How long the fade lasts
            // Fade Start: Duration of file - Fade start = When fade starts after file is playing
            AudioManager.shared.loadPlayer(with: file, fadeDuration: 0.25, fadeStart: 500)
        } catch {
            print("Error: Can't load file:\(error.localizedDescription)")
        }
    }
    
    @IBAction func tappedScheduledSample(_ sender: Any) {
    
    }
    
    @objc func updateLabel() {
        DispatchQueue.main.async {
            self.playingSampleLabel.text = "Ready"
        }
    }
}

