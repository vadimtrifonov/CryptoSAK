import ArgumentParser
import CodableCSV
import CoinTracking
import Foundation
import Gate

struct GateBillingStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "gate-billing-statement",
        abstract: "Convert Gate.io billing history",
        discussion: "Accepts Gate.io billing history CSV file. Takes into account all fees"
    )

    @Argument(help: "Path to a Gate.io billing CSV file")
    var csvPath: String

    func run() throws {
        let gateRows = try Self.decodeGateBillingCSV(path: csvPath)
        let statement = try GateStatement(rows: gateRows)
        try CoinTrackingCSVEncoder().encode(rows: statement.toCoinTrackingRows(), filename: "GateBillingStatement")
    }

    static func decodeGateBillingCSV(path: String) throws -> [GateBillingRow] {
        let decoder = CSVDecoder { configuration in
            configuration.headerStrategy = .firstLine
            configuration.delimiters.field = "\t"
        }
        return try decoder.decode([GateBillingRow].self, from: URL(fileURLWithPath: path))
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
        let type: TransactionType

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
            type = .incoming(.interestIncome)
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
            comment: Self.makeComment(),
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
            comment: Self.makeComment(),
            date: trade.date
        )
    }
}
