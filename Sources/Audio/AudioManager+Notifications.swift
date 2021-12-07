//
//  AudioManager+Notifications.swift
//  TestSMAKApp
//
//  Created by Maximilian Maksutovic on 12/9/21.
//

import Foundation
import AVFoundation
import UIKit

extension AudioManager {
    internal func registerForNotifications() {
        notifier.addObserver(self,
                             selector: #selector(handleInterruption),
                             name: AVAudioSession.interruptionNotification,
                             object: nil)
        notifier.addObserver(self,
                             selector: #selector(enterBackground),
                             name: UIApplication.didEnterBackgroundNotification,
                             object: nil)
        notifier.addObserver(self,
                             selector: #selector(enterForeground),
                             name: UIApplication.willEnterForegroundNotification,
                             object: nil)
        notifier.addObserver(self,
                             selector: #selector(handleRouteChange),
                             name: AVAudioSession.routeChangeNotification,
                             object: nil)
        notifier.addObserver(self,
                             selector: #selector(handleRouteChange),
                             name: .AVAudioEngineConfigurationChange,
                             object: nil)
        notifier.addObserver(self,
                             selector: #selector(handleRouteChange),
                             name: AVAudioSession.mediaServicesWereResetNotification,
                             object: nil)
    }
    
    @objc internal func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            print("In handleInterruption: type == .began")
            restartEngine()
        } else if type == .ended {
             print("In handleInterruption: type == .ended")
            stopEngine()
        }
    }

    @objc internal func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            if notification.name == .AVAudioEngineConfigurationChange {
                print(AVAudioSession.sharedInstance().currentRoute)
            }
            return
        }
        DispatchQueue.main.async {
            switch reason {
                case .newDeviceAvailable:
                    self.restartEngine()
                case .oldDeviceUnavailable:
                    self.restartEngine()
                case .categoryChange:
                    self.getCategory()
                default:
                    break
            }
        }
    }

    @objc func enterBackground() {
        print("Entering background")
        self.applicationState = .background
        stopEngine()
    }

    @objc func enterForeground() {
        print("Entering Foreground")
        self.applicationState = .foreground
        restartEngine()
    }
    
    func getCategory()
    {
        let category = AVAudioSession.sharedInstance().category
        
        switch category {
        case AVAudioSession.Category.ambient:
            print("Category is Ambient")
        case AVAudioSession.Category.multiRoute:
            print("Category is MultiRoute")
        case AVAudioSession.Category.playAndRecord:
            print("Category is PlayAndRecord")
        case AVAudioSession.Category.playback:
            print("Category is Playback")
        case AVAudioSession.Category.record:
            print("Category is Playback")
        case AVAudioSession.Category.soloAmbient:
            print("Category is soloAmbient")
        default:
            print("Noidea what enum this is:\(category)")
        }
    }
}

enum ApplicationState: String {
    case foreground = "Foreground"
    case resignActive = "resignActive"
    case background = "background"
}
