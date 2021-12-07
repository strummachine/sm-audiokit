import Foundation
import AudioKit
import AVFoundation
import AudioKitEX

class SamplePlayback {
    var samplePlayer: SamplePlayer?
    var playbackId: String
    var sampleId: String
    var duration: Double

    init (
        samplePlayer: SamplePlayer,
        sampleId: String,
        playbackId: String,
        duration: Double
    ) {
        self.samplePlayer = samplePlayer
        self.playbackId = playbackId
        self.sampleId = sampleId
        self.duration = duration
    }
    
    func fade(at: AVAudioTime, to: Double, duration: Double) {
        self.samplePlayer?.fade(at: at, to: to, duration: duration)
    }
  
    func changePlaybackRate(at: AVAudioTime, to: Double, duration: Double ) {
        self.samplePlayer?.changePlaybackRate(at: at, to: to, duration: duration)
    }

    func stop(at: AVAudioTime?) {
        self.samplePlayer?.stop(at: at)
    }
}
