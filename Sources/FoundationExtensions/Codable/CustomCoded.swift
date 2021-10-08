@propertyWrapper
public struct CustomCoded<CustomCoder: AnyCustomCoding> {
    public let wrappedValue: CustomCoder.Value

    public init(wrappedValue: CustomCoder.Value) {
        self.wrappedValue = wrappedValue
    }
}

extension CustomCoded: Decodable, CustomDecodable where CustomCoder: CustomDecoding {
    public typealias CustomDecoder = CustomCoder
}

extension CustomCoded: Encodable, CustomEncodable where CustomCoder: CustomEncoding {
    public typealias CustomEncoder = CustomCoder
}

extension CustomCoded: Equatable where CustomCoder.Value: Equatable {}
extension CustomCoded: Hashable where CustomCoder.Value: Hashable {}
