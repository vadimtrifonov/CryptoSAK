import Foundation

public struct TezosDelegationOperation: TezosOperation {
    public let hash: String
    public let sender: String
    public let delegate: String
    public let fee: Decimal
    public let timestamp: Date
    public let isSuccessful: Bool

    public init(
        hash: String,
        sender: String,
        delegate: String,
        fee: Decimal,
        timestamp: Date,
        isSuccessful: Bool
    ) {
        self.hash = hash
        self.sender = sender
        self.delegate = delegate
        self.fee = fee
        self.timestamp = timestamp
        self.isSuccessful = isSuccessful
    }
}

extension TezosDelegationOperation: Equatable {
    public static func == (lhs: TezosDelegationOperation, rhs: TezosDelegationOperation) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension TezosDelegationOperation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}

extension TezosDelegationOperation: Comparable {
    public static func < (lhs: TezosDelegationOperation, rhs: TezosDelegationOperation) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}
