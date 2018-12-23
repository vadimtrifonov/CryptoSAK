import Foundation

public struct CoinTrackingRow: Equatable {
    
    enum `Type`: String {
        case trade = "Trade"
        case withdrawal = "Withdrawal"
        case deposit = "Deposit"
        case giftOrTip = "Gift/Tip"
        case lost = "Lost"
    }
    
    let type: Type
    let buyAmount: Decimal
    let buyCurrency: String
    let sellAmount: Decimal
    let sellCurrency: String
    let fee: Decimal
    let feeCurrency: String
    let exchange: String
    let group: String
    let comment: String
    let date: Date
}

extension CoinTrackingRow: Comparable {
    
    public static func < (lhs: CoinTrackingRow, rhs: CoinTrackingRow) -> Bool {
        return lhs.date < rhs.date
    }
}
