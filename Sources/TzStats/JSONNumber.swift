import Foundation
import FoundationExtensions

/// Conversion through String produces a more truthful value, see https://bugs.swift.org/browse/SR-7054
struct JSONNumber: Hashable, Decodable {
    let decimal: Decimal

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let doubleValue = try container.decode(Double.self)
        self.decimal = try Decimal(string: "\(doubleValue)")
    }
}
