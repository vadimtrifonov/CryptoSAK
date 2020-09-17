extension RawRepresentable where RawValue == String {

    public init(string: String) throws {
        guard let value = Self(rawValue: string) else {
            throw "Invalid value \(string)"
        }
        self = value
    }
}
