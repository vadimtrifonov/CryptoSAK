import Foundation
import FoundationExtensions

public struct IDEXBalanceRow {

    public enum OperationType: String {
        case withdrawal = "Withdrawal"
        case deposit = "Deposit"
    }

    @CustomCoded<RFC3339LocalTime> public var date: Date
    public let currency: String
    public let operationType: OperationType
    public let name: String
    public let amount: Decimal
    public let status: String
    public let transactionHash: String
}

extension IDEXBalanceRow: Decodable {

    enum CodingKeys: Int, CodingKey {
        case date
        case currency
        case operationType
        case name
        case amount
        case status
        case transactionHash
    }
}

extension IDEXBalanceRow.OperationType: Decodable {}

extension IDEXBalanceRow {

    public enum TransactionType {
        case ethereum
        case token
    }

    public var transactionType: TransactionType {
        currency == "ETH" ? .ethereum : .token
    }
}
