import Foundation

public struct TezosOperation {
    public let hash: String
    public let source: Source
    public let destination: Destination
    public let amount: Decimal
    public let fee: Decimal
    public let timestamp: Date
    public let isSuccessful: Bool

    public init(
        hash: String,
        source: Source,
        destination: Destination,
        amount: Decimal,
        fee: Decimal,
        timestamp: Date,
        isSuccessful: Bool
    ) {
        self.hash = hash
        self.source = source
        self.destination = destination
        self.amount = amount
        self.fee = fee
        self.timestamp = timestamp
        self.isSuccessful = isSuccessful
    }

    public func isIncoming(account: String) -> Bool {
        return destination.account.lowercased() == account.lowercased()
    }

    public func isOutgoing(account: String) -> Bool {
        return source.account.lowercased() == account.lowercased()
    }

    public struct Source {
        public let account: String
        public let alias: String?

        public init(account: String, alias: String? = nil) {
            self.account = account
            self.alias = alias
        }
    }

    public struct Destination {
        public let account: String

        public init(account: String) {
            self.account = account
        }
    }
}

extension TezosOperation: Equatable {
    public static func == (lhs: TezosOperation, rhs: TezosOperation) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension TezosOperation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}

extension TezosOperation: Comparable {
    public static func < (lhs: TezosOperation, rhs: TezosOperation) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}
