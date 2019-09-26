import Foundation
import FoundationExtensions

public struct TzScanOperation: Decodable {
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

enum TzScanNumber: Decodable {
    case string(String)
    case integer(Int)

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            let integer = try container.decode(Int.self)
            self = .integer(integer)
        } catch {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            self = .string(string)
        }
    }

    func toDecimal() throws -> Decimal {
        switch self {
        case let .string(string):
            return try Decimal.make(string: string)
        case let .integer(integer):
            return Decimal(integer)
        }
    }
}
