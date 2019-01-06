import Foundation

public struct TokenTransaction {
    let hash: String
    let date: Date
    let from: String
    let to: String
    let amount: Decimal
    let fee: Decimal
    let contract: String
    let tokenSymbol: String
    let isSuccessful: Bool
}

extension TokenTransaction: Equatable {
    public static func == (lhs: TokenTransaction, rhs: TokenTransaction) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension TokenTransaction: Comparable {
    public static func < (lhs: TokenTransaction, rhs: TokenTransaction) -> Bool {
        return lhs.date < rhs.date
    }
}
