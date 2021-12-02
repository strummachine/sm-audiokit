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
        guard let package = AudioPackage() else {
            fatalError("Cannot unwrap package")
        }
        guard let url = package.extractAudioPackage() else {
            fatalError("Can't unwrap url")
        }
        do {
            let audioFile = try AVAudioFile(forReading: url)
            AudioManager.shared.loadPlayer(with: audioFile)
        } catch {
            print("Error: cannot load audio file:\(error)")
        }
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
    
    }
    
    @IBAction func tappedScheduledSample(_ sender: Any) {
    
    }
}

