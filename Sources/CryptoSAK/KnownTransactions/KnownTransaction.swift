import CoinTracking
import Foundation
import FoundationExtensions

struct KnownTransaction: Equatable {
    let type: CoinTrackingRow.TransactionType?
    let buyAmount: Decimal?
    let buyCurrency: String?
    let sellAmount: Decimal?
    let sellCurrency: String?
    let fee: Decimal?
    let feeCurrency: String?
    let exchange: String?
    let group: String?
    let comment: String?
    let date: Date?
    let transactionID: String?
}
