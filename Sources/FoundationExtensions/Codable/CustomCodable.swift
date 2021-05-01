public protocol CustomDecodable: Decodable {
    associatedtype CustomDecoder: CustomDecoding

    init(wrappedValue: CustomDecoder.Value)
}

extension CustomDecodable {

    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try CustomDecoder.decode(from: decoder))
    }
}

public protocol CustomEncodable: Encodable {
    associatedtype CustomEncoder: CustomEncoding

    var wrappedValue: CustomEncoder.Value { get }
}

extension CustomEncodable {

    public func encode(to encoder: Encoder) throws {
        try CustomEncoder.encode(value: wrappedValue, to: encoder)
    }
}
