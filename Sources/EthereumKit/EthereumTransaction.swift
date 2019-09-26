import Foundation

public struct EthereumTransaction {
    public let hash: String
    public let date: Date
    public let from: String
    public let to: String
    public let amount: Decimal
    public let fee: Decimal
    public let isSuccessful: Bool

    public init(
        hash: String,
        date: Date,
        from: String,
        to: String,
        amount: Decimal,
        fee: Decimal,
        isSuccessful: Bool
    ) {
        self.hash = hash
        self.date = date
        self.from = from
        self.to = to
        self.amount = amount
        self.fee = fee
        self.isSuccessful = isSuccessful
    }

    public func isIncoming(address: String) -> Bool {
        return to.lowercased() == address.lowercased()
    }

    public func isOutgoing(address: String) -> Bool {
        return from.lowercased() == address.lowercased()
    }
}

extension EthereumTransaction: Equatable {
    public static func == (lhs: EthereumTransaction, rhs: EthereumTransaction) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension EthereumTransaction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}

extension EthereumTransaction: Comparable {
    public static func < (lhs: EthereumTransaction, rhs: EthereumTransaction) -> Bool {
        return lhs.date < rhs.date
    }
}
