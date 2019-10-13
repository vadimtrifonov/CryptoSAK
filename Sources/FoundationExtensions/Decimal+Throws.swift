import Foundation

extension Decimal {
    public init(string: String) throws {
        guard let decimal = Decimal(string: string) else {
            throw "Invalid decimal \(string)"
        }
        self = decimal
    }
}
