import ArgumentParser
import CoinTracking
import Foundation
import IDEX

struct IDEXTradeStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "idex-trade-statement")

    @Argument(help: "Path to CSV file with IDEX trade history")
    var csvPath: String

    func run() throws {
        let csvRows = try FileManager.default.readLines(atPath: csvPath).dropFirst() // drop header row
        let tradeRows = try csvRows.map(IDEXTradeRow.init)
        let rows = tradeRows.map(CoinTrackingRow.init)
        try FileManager.default.writeCSV(rows: rows, filename: "IDEXTradeStatement")
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
            date: idexTradeRow.date,
            transactionID: idexTradeRow.transactionHash
        )
    }
}
