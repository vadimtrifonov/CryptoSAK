import Foundation
import FoundationExtensions
import HTTPClient
import TezosKit

public struct TzStats {

    public struct CycleInfo: Decodable {
        public let cycle: Int
        public let start_time: String
        public let end_time: String
    }

    public struct AccountOperations: Decodable {
        public let ops: [Operation]
    }

    public struct Operation: Decodable {
        let hash: String
        let type: String
        let time: String
        let is_success: Bool
        let volume: Decimal
        let fee: Decimal
        let sender: String
        let receiver: String?
        let delegate: String?
    }

    enum OperationType: String {
        case transaction
        case delegation
    }

    /// https://api.tzstats.com/explorer/cycle/head
    public static func makeCycleEndpoint(cycle: Int) throws -> Endpoint<CycleInfo> {
        try Endpoint(
            .get,
            url: URL(string: "https://api.tzstats.com/explorer/cycle/\(cycle)")
        )
    }

    /// https://api.tzstats.com/explorer/account/{hash}/op?limit={limit}&offset={offset}
    public static func makeAccountOperationsEndpoint(
        account: String,
        limit: Int,
        offset: Int
    ) throws -> Endpoint<AccountOperations> {
        try Endpoint(
            .get,
            url: URL(string: "https://api.tzstats.com/explorer/account/\(account)/op"),
            parameters: ["limit": limit, "offset": offset]
        )
    }
}

extension TzStats.Operation {
    private static let dateFormatter = ISO8601DateFormatter()

    func timestamp() throws -> Date {
        return try Self.dateFormatter.date(from: time)
    }
}

extension TzStats.Operation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}

extension TzStats.Operation: Comparable {
    public static func < (lhs: TzStats.Operation, rhs: TzStats.Operation) -> Bool {
        do {
            return try lhs.timestamp() < rhs.timestamp()
        } catch {
            return false
        }
    }
}