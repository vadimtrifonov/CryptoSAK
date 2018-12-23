import Foundation

public struct Transaction {
    let hash: String
    let date: Date
    let from: String
    let to: String
    let fee: Decimal
}

extension Transaction: Comparable {
    public static func < (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.date < rhs.date
    }
}
