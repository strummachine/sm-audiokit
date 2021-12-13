import Foundation
import AudioKit

class SamplePlayerPool {
    var players = [SamplePlayer]()
    var size: Int {
        get { self.players.count }
    }

    func createPlayers(count: Int) {
        for _ in 0..<count {
            self.players.append(SamplePlayer())
        }
    }
    
    func getPlayer(forSample sample: Sample) -> SamplePlayer {
        let sortedPlayers = self.players.sorted { a, b in
            return ((a.startTime?.hostTime ?? 0) < (b.startTime?.hostTime ?? 1))
        }
        return sortedPlayers.first(where: { $0.available && $0.sampleId == nil })
            ?? sortedPlayers.first(where: { $0.available })
            ?? sortedPlayers.first!
    }
    
    public func stopAllPlayers() {
        print("[SamplePlayerPool] Stopping all players")
        for player in players {
            player.stopImmediately()
        }
    }
    
    public func removeAllPlayers() {
        if self.players.contains(where: {!$0.available}) {
            print("Player was unavailable during teardown; this should never happen")
        }
        players.removeAll()
    }
}
