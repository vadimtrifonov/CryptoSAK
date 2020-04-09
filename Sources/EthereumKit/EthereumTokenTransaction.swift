import Foundation

public struct EthereumTokenTransaction {
    public let hash: String
    public let date: Date
    public let from: String
    public let to: String
    public let amount: Decimal
    public let fee: Decimal
    public let token: EthereumToken
    public let isSuccessful: Bool

    public init(
        hash: String,
        date: Date,
        from: String,
        to: String,
        amount: Decimal,
        fee: Decimal,
        token: EthereumToken,
        isSuccessful: Bool
    ) {
        self.hash = hash
        self.date = date
        self.from = from
        self.to = to
        self.amount = amount
        self.fee = fee
        self.token = token
        self.isSuccessful = isSuccessful
    }

    public func isIncoming(address: String) -> Bool {
        to.lowercased() == address.lowercased()
    }

    public func isOutgoing(address: String) -> Bool {
        from.lowercased() == address.lowercased()
    }
}

extension EthereumTokenTransaction: Equatable {
    public static func == (lhs: EthereumTokenTransaction, rhs: EthereumTokenTransaction) -> Bool {
        lhs.hash == rhs.hash
    }
}

extension EthereumTokenTransaction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}

extension EthereumTokenTransaction: Comparable {
    public static func < (lhs: EthereumTokenTransaction, rhs: EthereumTokenTransaction) -> Bool {
        lhs.date < rhs.date
    }
}
