import Foundation

extension Array where Element == String {

    public func dropFirst(withPrefix prefix: String) -> [String] {
        first?.hasPrefix(prefix) == true ? Array(dropFirst()) : self
    }
}
