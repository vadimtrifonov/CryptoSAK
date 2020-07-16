import Foundation
import FoundationExtensions
import Tezos

extension TezosCycle {
    private static let dateFormatter = ISO8601DateFormatter()

    public init(cycleInfo: TzStats.CycleInfo) throws {
        self.init(
            cycle: cycleInfo.cycle,
            start: try Self.dateFormatter.date(from: cycleInfo.start_time),
            end: try Self.dateFormatter.date(from: cycleInfo.end_time)
        )
    }
}
