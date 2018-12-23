import Foundation

extension Double {
    
    static func make(string: String) throws -> Double {
        guard let double = Double(string) else {
            throw "Invalid integer \(string)"
        }
        return double
    }
}
