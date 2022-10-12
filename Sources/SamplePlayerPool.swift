import Foundation
import AudioKit

final class SamplePlayerPool {
    private static var opLock = NSRecursiveLock()
    static var globalPlayerDict = [String:SamplePlayer]()

    static func withPlayer(playbackId: String, _ code: @escaping (_ value: SamplePlayer) -> ()) {
        opLock.lock()
        let player = globalPlayerDict[playbackId]
        opLock.unlock()
        if player != nil {
            code(player!)
        }
    }

    var players = [SamplePlayer]()
    var playersInUse = [String:SamplePlayer]()
    var playersAvailable = [SamplePlayer]()

    func createPlayers(count: Int) {
        SamplePlayerPool.opLock.lock()
        for _ in 0..<count {
            let player = SamplePlayer(pool: self)
            self.players.append(player)
            self.playersAvailable.append(player)
        }
        SamplePlayerPool.opLock.unlock()
    }
    
    func debugLine() -> String {
        SamplePlayerPool.opLock.lock()
        let result = String(players.count).padding(toLength: 3, withPad: " ", startingAt: 0) + " " + String(repeating: "X", count: self.playersInUse.values.filter({ $0.player.playerNode.isPlaying }).count) + String(repeating: "?", count: self.playersInUse.values.filter({ !$0.player.playerNode.isPlaying }).count) + String(repeating: "-", count: self.playersAvailable.count)
        SamplePlayerPool.opLock.unlock()
        return result
    }

    func reservePlayer(playbackId: String) -> SamplePlayer? {
        SamplePlayerPool.opLock.lock()
        let player = playersAvailable.popLast()
        if let availablePlayer = player {
            playersInUse[playbackId] = availablePlayer
            SamplePlayerPool.globalPlayerDict[playbackId] = availablePlayer
        }
        SamplePlayerPool.opLock.unlock()
        return player
    }

    func returnPlayer(_ player: SamplePlayer) {
        SamplePlayerPool.opLock.lock()
        if let playbackId = player.playbackId {
            player.reset()
            playersInUse.removeValue(forKey: playbackId)
            SamplePlayerPool.globalPlayerDict.removeValue(forKey: playbackId)
        } else {
            print("⛔️ Tried to returnPlayer with no playbackId!")
            print(player)
        }
        playersAvailable.insert(player, at: 0)
        SamplePlayerPool.opLock.unlock()
    }
    
    public func stopAllPlayers() {
        SamplePlayerPool.opLock.lock()
        for player in players {
            player.stopImmediately()
        }
        playersInUse.removeAll()
        SamplePlayerPool.globalPlayerDict.removeAll()
        playersAvailable = players  // in Swift, this is a copy
        SamplePlayerPool.opLock.unlock()
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
