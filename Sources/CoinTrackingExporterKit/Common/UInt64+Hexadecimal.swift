import Foundation

extension UInt64 {
    
    static func make(hexadecimal string: String) throws -> UInt64 {
        let string = string.hasPrefix("0x") ? String(string.dropFirst(2)) : string
        
        guard let int = UInt64(string, radix: 16) else {
            throw "Invalid hexadecimal \(string)"
        }
        
        return int
    }
}
