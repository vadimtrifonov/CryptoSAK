import Commander
import Foundation

extension Date: ArgumentConvertible {
    public init(parser: ArgumentParser) throws {
        guard let value = parser.shift() else {
            throw ArgumentError.missingValue(argument: nil)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate

        if let date = formatter.date(from: value) {
            self = date
        } else {
            throw ArgumentError.invalidType(value: value, type: "date", argument: nil)
        }
    }
}
