import Foundation

extension Int {
    
    static func make(hexadecimal string: String) throws -> Int {
        let string = string.hasPrefix("0x") ? String(string.dropFirst(2)) : string
        
        guard let int = Int(string, radix: 16) else {
            throw "Invalid hexadecimal \(string)"
        }
        
        return int
    }
}
