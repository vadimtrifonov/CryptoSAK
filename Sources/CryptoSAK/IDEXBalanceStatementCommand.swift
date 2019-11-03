import CoinTrackingKit
import Foundation
import IDEXKit

struct IDEXBalanceStatementCommand {

    static func execute(tsvPath: String) throws {
        let tsvPath = try File.read(path: tsvPath).dropFirst() // drop header row
        let tradeRows = try tsvPath.map(IDEXBalanceRow.init)
        let rows = tradeRows.map(CoinTrackingRow.init)
        try File.write(rows: rows, filename: "IDEXBalanceStatement")
    }
}

extension CoinTrackingRow {

    init(idexBalanceRow: IDEXBalanceRow) {
        var buy: Decimal = 0
        var buyCurrency: String = ""
        var sell: Decimal = 0
        var sellCurrency: String = ""
        let type: CoinTrackingRow.`Type`

        switch idexBalanceRow.type {
        case .withdrawal:
            sell = idexBalanceRow.amount
            sellCurrency = idexBalanceRow.currency
            type = .outgoing(.withdrawal)
        case .deposit:
            buy = idexBalanceRow.amount
            buyCurrency = idexBalanceRow.currency
            type = .incoming(.deposit)
        }

        self.init(
            type: type,
            buyAmount: buy,
            buyCurrency: buyCurrency,
            sellAmount: sell,
            sellCurrency: sellCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: "IDEX",
            group: "",
            comment: "Export",
            date: idexBalanceRow.date
        )
    }
}
