import Foundation

public struct TezosDelegationOperation: TezosOperation {
    public let hash: String
    public let source: Source
    public let delegate: Delegate
    public let fee: Decimal
    public let timestamp: Date
    public let isSuccessful: Bool

    public var sourceAccount: String {
        source.account
    }
    
    public init(
        hash: String,
        source: Source,
        delegate: Delegate,
        fee: Decimal,
        timestamp: Date,
        isSuccessful: Bool
    ) {
        self.hash = hash
        self.source = source
        self.delegate = delegate
        self.fee = fee
        self.timestamp = timestamp
        self.isSuccessful = isSuccessful
    }

    public struct Source {
        public let account: String

        public init(account: String) {
            self.account = account
        }
    }

    public struct Delegate {
        public let account: String
        public let alias: String?

        public init(account: String, alias: String? = nil) {
            self.account = account
            self.alias = alias
        }
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
