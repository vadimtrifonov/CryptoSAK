public protocol CustomCoding: CustomDecoding, CustomEncoding {}

public protocol CustomDecoding: AssociatedTypeProtocol {
    associatedtype Value

    static func decode(from decoder: Decoder) throws -> Value
}

public protocol CustomEncoding: AssociatedTypeProtocol {
    associatedtype Value

    static func encode(value: Value, to encoder: Encoder) throws
}

public protocol AssociatedTypeProtocol {
    associatedtype Value
}
