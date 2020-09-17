import Foundation

extension UInt64 {

    public init(hexadecimal string: String) throws {
        let string = string.hasPrefix("0x") ? String(string.dropFirst(2)) : string

        guard let int = UInt64(string, radix: 16) else {
            throw "Invalid hexadecimal \(string)"
        }

        self = int
    }
}
