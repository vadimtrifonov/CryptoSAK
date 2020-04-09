import ArgumentParser
import Foundation

extension Date: ExpressibleByArgument {

    public init?(argument: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate

        if let date = formatter.date(from: argument) {
            self = date
        } else {
            return nil
        }
    }
}
