import Foundation

extension Double {

    public init(string: String) throws {
        guard let double = Double(string) else {
            throw "Invalid double \(string)"
        }
        self = double
    }
}
