import Foundation

extension ISO8601DateFormatter {
    public func date(from string: String) throws -> Date {
        guard let date = date(from: string) else {
            throw "Ivalid date \(string), expected date with the format \(String(describing: formatOptions))"
        }
        return date
    }
}
