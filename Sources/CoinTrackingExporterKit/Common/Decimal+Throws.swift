import Foundation

extension Decimal {
    
    static func make(string: String) throws -> Decimal {
        guard let decimal = Decimal(string: string) else {
            throw "Invalid decimal \(string)"
        }
        return decimal
    }
}
