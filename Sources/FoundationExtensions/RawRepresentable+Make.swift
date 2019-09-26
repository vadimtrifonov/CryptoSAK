extension RawRepresentable where RawValue == String {
    public static func make(string: String) throws -> Self {
        guard let value = Self(rawValue: string) else {
            throw "Invalid value \(string)"
        }
        return value
    }
}
