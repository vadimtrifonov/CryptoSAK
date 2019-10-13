import CoinTrackingKit
import Foundation
import GateKit

struct GateBillingStatementCommand {

    func execute(csvPath: String) throws {
        let csvRows = try CSV.read(path: csvPath).dropFirst() // drop header row
        let gateRows = try csvRows.map(GateBillingRow.init)
        let statement = try GateStatement(rows: gateRows)
        try write(rows: statement.toCoinTrackingRows(), filename: "GateBillingStatement")
    }
}

private extension GateStatement {

    func toCoinTrackingRows() throws -> [CoinTrackingRow] {
        let rows = try transactions.map(CoinTrackingRow.init) + trades.map(CoinTrackingRow.init)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {

    init(transaction: GateTransaction) throws {
        var buy: Decimal = 0
        var buyCurrency: String = ""
        var sell: Decimal = 0
        var sellCurrency: String = ""
        let type: Type

        switch transaction.type {
        case .withdrawal:
            sell = transaction.amount
            sellCurrency = transaction.currency
            type = .outgoing(.withdrawal)
        case .deposit:
            buy = transaction.amount
            buyCurrency = transaction.currency
            type = .incoming(.deposit)
        case .airdrop:
            buy = transaction.amount
            buyCurrency = transaction.currency
            type = .incoming(.giftOrTip)
        }

        self.init(
            type: type,
            buyAmount: buy,
            buyCurrency: buyCurrency,
            sellAmount: sell,
            sellCurrency: sellCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: "Gate.io",
            group: "",
            comment: "Export",
            date: transaction.date
        )
    }
}

extension CoinTrackingRow {

    init(trade: GateTrade) throws {
        self.init(
            type: .trade,
            buyAmount: trade.buyAmount,
            buyCurrency: trade.buyCurrency,
            sellAmount: trade.sellAmount,
            sellCurrency: trade.sellCurrency,
            fee: trade.fee,
            feeCurrency: trade.feeCurrency,
            exchange: "Gate.io",
            group: "",
            comment: "Export",
            date: trade.date
        )
    }
}
