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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        if let audioPackages = AudioPackageExtractor.extractAudioPackage() {
            let shuffled = audioPackages.shuffled()
            let random = shuffled[0]
            
            do {
                let file = try AVAudioFile(forReading: random.url)
                AudioManager.shared.loadPlayer(with: file)
            } catch {
                print("Error: Can't load file:\(error.localizedDescription)")
            }
        }
        else {
            print("Can't unwrap audiopackages")
        }

    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
    
    }
    
    @IBAction func tappedScheduledSample(_ sender: Any) {
    
    }
}

