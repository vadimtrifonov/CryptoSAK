import Foundation

extension String {
    public init(data: Data, encoding: Encoding) throws {
        guard let string = String(data: data, encoding: encoding) else {
            throw "Invalid data \(data)"
        }
        self = string
    }
}
