import Foundation

public struct EthereumInternalTransaction {
    public let transaction: EthereumTransaction
    public let from: String
    public let to: String
    public let amount: Decimal

    public init(
        transaction: EthereumTransaction,
        from: String,
        to: String,
        amount: Decimal
    ) {
        self.from = from
        self.to = to
        self.amount = amount
        self.transaction = transaction
    }
}
