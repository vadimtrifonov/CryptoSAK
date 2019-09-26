import Foundation

extension Int {
    public static func make(string: String) throws -> Int {
        guard let integer = Int(string) else {
            throw "Invalid integer \(string)"
        }
        return integer
    }
}
