import Foundation
import FoundationExtensions

struct TzScanTransactionOperation: Decodable {
    let hash: String
    let block_hash: String
    let type: OperationType

    struct OperationType: Decodable {
        let kind: String
        let operations: [Operation]
        let source: Source

        struct Operation: Decodable {
            let `internal`: Bool
            let amount: TzScanNumber
            let src: Source
            let fee: TzScanNumber
            let timestamp: String
            let destination: Destination
            let kind: String
            let failed: Bool

            struct Destination: Decodable {
                let tz: String
            }
        }

        struct Source: Decodable {
            let alias: String?
            let tz: String
        }
    }
}

extension TzScanTransactionOperation: TzScanOperation {
    private static let dateFormatter = ISO8601DateFormatter()

    func timestamp() throws -> Date {
        guard let operation = type.operations.first else {
            throw "No operation in \(self)"
        }
        return try Self.dateFormatter.makeDate(string: operation.timestamp)
    }
}
