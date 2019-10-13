import Foundation

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
            return try Decimal(string: string)
        case let .integer(integer):
            return Decimal(integer)
        }
    }
}
