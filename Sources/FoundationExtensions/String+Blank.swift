
extension String {

    public var nonBlank: String? {
        isBlank ? nil : self
    }

    public var isBlank: Bool {
        allSatisfy { $0.isWhitespace }
    }
}
