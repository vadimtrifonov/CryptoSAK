import Foundation

public struct TezosCycle {
    public let cycle: Int
    public let start: Date
    public let end: Date

    public init(cycle: Int, start: Date, end: Date) {
        self.cycle = cycle
        self.start = start
        self.end = end
    }
}
