//
//  ViewController.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/18/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var scheduleSampleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let package = AudioPackage() else {
            fatalError("Cannot unwrap package")
        }
        package.extractAudioPackage()
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedRandomSample(_ sender: Any) {
        
    }
    
    @IBAction func tappedScheduled200ms(_ sender: Any) {
    
    }
    
    @IBAction func tappedScheduledSample(_ sender: Any) {
    
    }
}

