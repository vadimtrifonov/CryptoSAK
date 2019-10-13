import Foundation

extension Dictionary where Key == String, Value == Any {
    public func toFormURLEncoded() -> String {
        return flatMap { queryComponents(fromKey: $0, value: $1) }
            .map { "\($0)=\($1)" }
            .joined(separator: "&")
    }

    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.flatMap { queryComponents(fromKey: "\(key)[\($0)]", value: $1) }
        case let array as [Any]:
            return array.flatMap { queryComponents(fromKey: "\(key)[]", value: $0) }
        case let bool as Bool:
            return [(escape(key), escape(bool ? "1" : "0"))]
        default:
            return [(escape(key), escape("\(value)"))]
        }
    }

    private func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // no "?" or "/" see RFC 3986 Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
}
