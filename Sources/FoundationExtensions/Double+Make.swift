import Foundation

extension Double {
    public static func make(string: String) throws -> Double {
        guard let double = Double(string) else {
            throw "Invalid double \(string)"
        }
        return double
    }
}
