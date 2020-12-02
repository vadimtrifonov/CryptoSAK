import Foundation

extension Int {

    public init(string: String) throws {
        guard let integer = Int(string) else {
            throw "Invalid integer \(string)"
        }
        self = integer
    }
}

extension UInt {

    public init(string: String) throws {
        guard let integer = UInt(string) else {
            throw "Invalid unsigned integer \(string)"
        }
        self = integer
    }
}
