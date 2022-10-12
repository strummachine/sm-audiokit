import Foundation
import AudioKit
import AVFoundation
import AudioKitEX
import CAudioKitEX

public class BasicAudioPlayer: Node {
    /// Nodes providing input to this node.
    public var connections: [Node] { [] }

    /// The underlying player node
    public private(set) var playerNode = AVAudioPlayerNode()

    /// The internal AVAudioEngine AVAudioNode
    public var avAudioNode: AVAudioNode { return playerNode }

    /// Whether or not the playing is playing
    public internal(set) var isPlaying: Bool = false

    /// Will be true if there is an existing schedule event
    public var isScheduled: Bool { scheduleTime != nil }

    /// Length of the audio buffer in seconds
    public var duration: TimeInterval {
        guard let buffer = buffer else { return 0 }
        return TimeInterval(buffer.frameLength) / buffer.format.sampleRate
    }

    /// Completion handler to be called when file or buffer is done playing.
    public var completionHandler: AVAudioNodeCompletionHandler?

    /// The buffer to use with the player. This can be set while the player is playing
    public var buffer: AVAudioPCMBuffer? {
        didSet {
            scheduleTime = nil
            if isPlaying { stop() }
            if isPlaying && buffer != nil { play() }
        }
    }

    private var _editStartTime: TimeInterval = 0
    /// Get or set the edit start time of the player.
    public var editStartTime: TimeInterval {
        get { _editStartTime }
        set {
            _editStartTime = min(max(newValue, 0), duration)
        }
    }

    // MARK: - Internal properties

    // the last time scheduled. Only used to check if play() should schedule()
    var scheduleTime: AVAudioTime?

    var engine: AVAudioEngine? { playerNode.engine }

    // MARK: - Internal functions

    func internalCompletionHandler() {
        // TODO: Make this thread-safe
//        guard isPlaying, engine?.isInManualRenderingMode == false else { return }
        guard isPlaying else { return }

        scheduleTime = nil
        isPlaying = false

        completionHandler?()
    }

    // MARK: - Init

    public init() {}

    deinit {
        buffer = nil
    }

    // MARK: - Playback

    /// Play now or at a future time
    /// - Parameters:
    ///   - when: What time to schedule for. A value of nil means now or will
    ///   use a pre-existing scheduled time.
    ///   - completionCallbackType: Constants that specify when the completion handler must be invoked.
    public func play(from startTime: TimeInterval? = nil,
                     to endTime: TimeInterval? = nil,
                     at when: AVAudioTime? = nil,
                     completionCallbackType: AVAudioPlayerNodeCompletionCallbackType = .dataPlayedBack) {

        if isPlaying {
            stop()
        }

        guard let engine = playerNode.engine else {
            Log("🛑 Error: Player must be attached before playback.", type: .error)
            return
        }

        guard engine.isRunning else {
            Log("🛑 Error: Player's engine must be running before playback.", type: .error)
            return
        }

        if when != nil {
            scheduleTime = nil
            if playerNode.isPlaying {
                playerNode.stop()
            }
        }

        editStartTime = startTime ?? editStartTime

        if !isScheduled {
            schedule(at: when,
                     completionCallbackType: completionCallbackType)
        }

        playerNode.play()
        isPlaying = true
    }

    /// Gets the accurate playhead time regardless of seeking and pausing
    /// Can't be relied on if playerNode has its playstate modified directly
    public func getCurrentTime() -> TimeInterval {
        if let nodeTime = playerNode.lastRenderTime,
           nodeTime.isSampleTimeValid,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            return (Double(playerTime.sampleTime) / playerTime.sampleRate) + editStartTime
        }
        return editStartTime
    }

    /// Stop audio player. This won't generate a callback event
    public func stop() {
        guard isPlaying else { return }
        isPlaying = false
        playerNode.stop()
        scheduleTime = nil
    }




    /// Schedule a file or buffer. You can call this to schedule playback in the future
    /// or the player will call it when play() is called to load the audio data
    /// - Parameters:
    ///   - when: What time to schedule for
    ///   - completionCallbackType: Constants that specify when the completion handler must be invoked.
    public func schedule(at when: AVAudioTime? = nil,
                         completionCallbackType: AVAudioPlayerNodeCompletionCallbackType = .dataPlayedBack) {
        scheduleTime = when ?? AVAudioTime.now()

        guard let buffer = buffer else {
            Log("⚠️ Trying to schedule player with no buffer")
            return
        }

        if playerNode.outputFormat(forBus: 0) != buffer.format {
            Log("⚠️ Format of the buffer doesn't match the player")
            Log("Player:", playerNode.outputFormat(forBus: 0), "Buffer", buffer.format)
            Log("Buffer:", buffer.format)
        }

        var bufferOptions: AVAudioPlayerNodeBufferOptions = [.interrupts]

        playerNode.scheduleBuffer(buffer,
                                  at: scheduleTime,
                                  options: bufferOptions,
                                  completionCallbackType: completionCallbackType) { callbackType in
            self.internalCompletionHandler()
        }

        playerNode.prepare(withFrameCount: buffer.frameLength)
    }

}
