import Foundation
import AudioKit

class SamplePlayerPool {
    var players = [SamplePlayer]()
    var size: Int {
        get { self.players.count }
    }

    init(size: Int) {
        for _ in 0..<size {
            self.players.append(SamplePlayer())
        }
    }

    func getPlayer(forSample sample: Sample) -> SamplePlayer {
        let debugPreloadedCount = self.players.filter({ $0.available && $0.sampleId == sample.id }).count
        print("Getting player for \(sample.id.padding(toLength: 15, withPad: " ", startingAt: 0)) - \(self.players.filter({ $0.available }).count) of \(self.size) available, \(debugPreloadedCount > 0 ? String(debugPreloadedCount) : "ZERO") preloaded")
        let playerWithSampleLoaded = self.players.first(where: { $0.available && $0.sampleId == sample.id })
        if playerWithSampleLoaded != nil {
            return playerWithSampleLoaded!
        }
        let sortedPlayers = self.players.sorted { a, b in
            return ((a.startTime?.hostTime ?? 0) < (b.startTime?.hostTime ?? 0))
        }
        return sortedPlayers.first(where: { $0.available && $0.sampleId == nil })
            ?? sortedPlayers.first(where: { $0.available })
            ?? sortedPlayers.first!
    }
}
