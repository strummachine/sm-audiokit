import Foundation
import AudioKit

final class SamplePlayerPool {
    var arrayLock = NSRecursiveLock()

    static var globalArrayLock = NSRecursiveLock()
    static var globalPlayerDict = [String:SamplePlayer]()

    static func withPlayer(playbackId: String, _ code: @escaping (_ value: SamplePlayer) -> ()) {
        globalArrayLock.lock()
        let player = globalPlayerDict[playbackId]
        globalArrayLock.unlock()
        if player != nil {
            code(player!)
        }
    }

    var players = [SamplePlayer]()
    var playersInUse = [String:SamplePlayer]()
    var playersAvailable = [SamplePlayer]()

    func createPlayers(count: Int) {
        SamplePlayerPool.globalArrayLock.lock()
        for _ in 0..<count {
            let player = SamplePlayer(pool: self)
            self.players.append(player)
            self.playersAvailable.append(player)
        }
        SamplePlayerPool.globalArrayLock.unlock()
    }
    
    func debugLine() -> String {
        SamplePlayerPool.globalArrayLock.lock()
        let result = String(repeating: "X", count: self.playersInUse.count) + String(repeating: "-", count: self.playersAvailable.count)
        SamplePlayerPool.globalArrayLock.unlock()
        return result
    }

    func reservePlayer(playbackId: String) -> SamplePlayer? {
        SamplePlayerPool.globalArrayLock.lock()
        let player = playersAvailable.popLast()
        if let availablePlayer = player {
            playersInUse[playbackId] = availablePlayer
            SamplePlayerPool.globalPlayerDict[playbackId] = player
        }
        SamplePlayerPool.globalArrayLock.unlock()
        return player
    }

    func returnPlayer(_ player: SamplePlayer) {
        SamplePlayerPool.globalArrayLock.lock()
        if let playbackId = player.playbackId {
            player.reset()
            playersInUse.removeValue(forKey: playbackId)
            SamplePlayerPool.globalPlayerDict.removeValue(forKey: playbackId)
        }
        playersAvailable.insert(player, at: 0)
        SamplePlayerPool.globalArrayLock.unlock()
    }
    
    public func stopAllPlayers() {
        SamplePlayerPool.globalArrayLock.lock()
        for player in players {
            player.stopImmediately()
        }
        SamplePlayerPool.globalArrayLock.unlock()
    }

    /*
    public func removeAllPlayers() {
        SamplePlayerPool.globalArrayLock.lock()
        players.removeAll()
        playersInUse.removeAll()
        playersAvailable.removeAll()
        SamplePlayerPool.globalArrayLock.unlock()
    }
     */
}
