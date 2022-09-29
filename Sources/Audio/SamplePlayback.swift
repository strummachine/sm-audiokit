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
        self.samplePlayer?.scheduleFade(at: at, to: to, duration: duration)
    }

    func stop(at: AVAudioTime?, fadeDuration: Double?) {
        self.samplePlayer?.scheduleStop(at: at, fadeDuration: fadeDuration)
    }
}
