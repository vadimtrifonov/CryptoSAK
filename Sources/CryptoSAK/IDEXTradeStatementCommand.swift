import CoinTrackingKit
import Foundation
import IDEXKit

struct IDEXTradeStatementCommand {

    static func execute(csvPath: String) throws {
        let csvRows = try File.read(path: csvPath).dropFirst() // drop header row
        let tradeRows = try csvRows.map(IDEXTradeRow.init)
        let rows = tradeRows.map(CoinTrackingRow.init)
        try File.write(rows: rows, filename: "IDEXTradeStatement")
    }
}

extension CoinTrackingRow {

    init(idexTradeRow: IDEXTradeRow) {
        let fee: Decimal
        let feeCurrency: String
        var buy: Decimal
        let buyCurrency: String
        let sell: Decimal
        let sellCurrency: String

        switch idexTradeRow.tradeType {
        case .buy:
            fee = idexTradeRow.fee
            feeCurrency = idexTradeRow.market.baseCurrency
            buy = idexTradeRow.tokenAmount - fee
            buyCurrency = idexTradeRow.market.baseCurrency
            sell = idexTradeRow.etherAmount
            sellCurrency = idexTradeRow.market.quoteCurrency
        case .sell:
            fee = idexTradeRow.fee + (idexTradeRow.gasFee ?? 0)
            feeCurrency = idexTradeRow.market.quoteCurrency
            buy = idexTradeRow.etherAmount - fee
            buyCurrency = idexTradeRow.market.quoteCurrency
            sell = idexTradeRow.tokenAmount
            sellCurrency = idexTradeRow.market.baseCurrency
        }

        self.init(
            type: .trade,
            buyAmount: buy,
            buyCurrency: buyCurrency,
            sellAmount: sell,
            sellCurrency: sellCurrency,
            fee: fee,
            feeCurrency: feeCurrency,
            exchange: "IDEX",
            group: "",
            comment: "Export. Transaction: \(idexTradeRow.transactionHash)",
            date: idexTradeRow.date
        )
    }
}