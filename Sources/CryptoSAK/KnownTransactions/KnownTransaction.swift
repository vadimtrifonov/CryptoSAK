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
    let transactionID: String
}

extension KnownTransaction: Decodable {

    enum CodingKeys: String, CaseIterable, CodingKey {
        case type = "Type"
        case buyAmount = "Buy Amount"
        case buyCurrency = "Buy Currency"
        case sellAmount = "Sell Amount"
        case sellCurrency = "Sell Currency"
        case fee = "Fee"
        case feeCurrency = "Fee Currency"
        case exchange = "Exchange"
        case group = "Trade-Group"
        case comment = "Comment"
        case date = "Date"
        case transactionID = "Tx-ID"
    }

    static var csvHeaders: [String] {
        CodingKeys.allCases.map(\.rawValue)
    }
}
