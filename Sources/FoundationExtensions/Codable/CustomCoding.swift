public protocol CustomCoding: CustomDecoding, CustomEncoding {}

public protocol CustomDecoding: AnyCustomCoding {
    associatedtype Value

    static func decode(from decoder: Decoder) throws -> Value
}

public protocol CustomEncoding: AnyCustomCoding {
    associatedtype Value

    static func encode(value: Value, to encoder: Encoder) throws
}

public protocol AnyCustomCoding {
    associatedtype Value
}
