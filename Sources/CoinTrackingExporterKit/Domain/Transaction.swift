import Foundation

public struct Transaction {
    let hash: String
    let date: Date
    let from: String
    let to: String
    let amount: Decimal
    let fee: Decimal
    let tokenSymbol: String?
}

extension Transaction: Equatable {
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension Transaction: Comparable {
    public static func < (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.date < rhs.date
    }
}
