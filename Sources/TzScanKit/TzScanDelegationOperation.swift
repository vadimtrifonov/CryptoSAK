import Foundation
import FoundationExtensions

struct TzScanDelegationOperation: Decodable {
    let hash: String
    let block_hash: String
    let type: OperationType

    struct OperationType: Decodable {
        let kind: String
        let operations: [Operation]
        let source: Source

        struct Operation: Decodable {
            let `internal`: Bool
            let src: Source
            let fee: TzScanNumber
            let timestamp: String
            let delegate: Delegate
            let kind: String
            let failed: Bool

            struct Delegate: Decodable {
                let tz: String
                let alias: String?
            }
        }

        struct Source: Decodable {
            let tz: String
        }
    }
}

extension TzScanDelegationOperation: TzScanOperation {
    private static let dateFormatter = ISO8601DateFormatter()

    func timestamp() throws -> Date {
        guard let operation = type.operations.first else {
            throw "No operation in \(self)"
        }
        return try Self.dateFormatter.makeDate(string: operation.timestamp)
    }
}
