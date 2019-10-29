import Foundation

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value.description)!
    }
}

extension URL {
    public init(string: String) throws {
        guard let url = URL(string: string) else {
            throw "Invalid url string \(string)"
        }
        self = url
    }
}
