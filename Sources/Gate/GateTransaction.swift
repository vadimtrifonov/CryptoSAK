import Foundation

public struct GateTransaction {

    public enum TransactionType {
        case airdrop
        case deposit
        case withdrawal
    }

    public let type: TransactionType
    public let date: Date
    public let amount: Decimal
    public let currency: String
}
