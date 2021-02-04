import ArgumentParser
import CoinTracking
import Foundation

struct BlockstackICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "blockstack-ico-statement",
        abstract: "Convert Blockstack ICO token unlocking information",
        shouldDisplay: false
    )

    @Argument(help: "Blockstack address")
    var address: String

    @Argument(
        help: .init(
            "Path to a CSV file with the information about ICO",
            discussion: """
            - One row (no header row)
            - Format: <ico-name>,<contribution-amount>,<contribution-currency>,<contribution-timestamp>
            """
        ))
    var icoCSVPath: String

    @Argument(help: "Path to a CSV file with the Stacks cumulative vested payouts")
    var payoutsCSVPath: String

    func run() throws {
        let icoCSVRows = try FileManager.default.readLines(atPath: icoCSVPath)
        let icos = try icoCSVRows.map(BlockstackICO.init)

        guard let ico = icos.first, icos.count == 1 else {
            throw """
            There should be only 1 ICO entry in the CSV file,
            as payouts from the other file are taken as corresponding to this ICO.
            """
        }

        let payoutCSVRows = try FileManager.default.readLines(atPath: payoutsCSVPath)
        let payoutRows = try payoutCSVRows.map(BlockstackVestedPayoutRow.init)

        let payouts = Self.toNonCumulativePayouts(rows: payoutRows)
        let icoRows = Self.makeICOCoinTrackingRows(ico: ico, payouts: payouts)
        let depositRows = payouts.map({ CoinTrackingRow.makeDeposit(address: address, payout: $0) })
        let rows = (icoRows + depositRows).sorted(by: >)

        try FileManager.default.writeCSV(rows: rows, filename: "BlockstackICOStatementCommand")
    }
}

extension BlockstackICOStatementCommand {

    static func toNonCumulativePayouts(rows: [BlockstackVestedPayoutRow]) -> [BlockstackVestedPayout] {
        rows.enumerated().map { index, payout in
            let previousIndex = rows.index(before: index)
            let previousCumulativeAmount = rows[safe: previousIndex]?.cumulativeAmount ?? 0
            let amount = payout.cumulativeAmount - previousCumulativeAmount
            return BlockstackVestedPayout(timestamp: payout.timestamp, amount: amount)
        }
    }

    static func makeICOCoinTrackingRows(
        ico: BlockstackICO,
        payouts: [BlockstackVestedPayout]
    ) -> [CoinTrackingRow] {

        let payoutTransactionRows = payouts.map { payout in
            CoinTrackingRow.makeWithdrawal(ico: ico, payout: payout)
        }

        let totalPayoutAmount = payouts.reduce(0, { $0 + $1.amount })
        let tradeRow = CoinTrackingRow.makeTrade(ico: ico, totalPayoutAmount: totalPayoutAmount)

        return payoutTransactionRows + [tradeRow]
    }
}

enum Blockstack {
    static let ticker = "STX2" // CoinTracking ticker
    static let microStacksInStack = Decimal(pow(10, 6))
}

struct BlockstackVestedPayout {
    let timestamp: Date
    let amount: Decimal
}

struct BlockstackICO {
    let name: String
    let contributionAmount: Decimal
    let contributionCurrency: String
    let timestamp: Date
}

extension BlockstackICO {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 4
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns)"
        }

        self.init(
            name: columns[0],
            contributionAmount: try Decimal(string: columns[1]),
            contributionCurrency: columns[2],
            timestamp: try ISO8601DateFormatter().date(from: columns[3])
        )
    }
}

struct BlockstackVestedPayoutRow {
    let timestamp: Date
    let cumulativeAmount: Decimal
}

extension BlockstackVestedPayoutRow {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 2
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns)"
        }

        let timestamp = try Date(timeIntervalSince1970: TimeInterval(string: columns[0]))
        let amount = try Decimal(string: columns[1]) / Blockstack.microStacksInStack

        self.init(
            timestamp: timestamp,
            cumulativeAmount: amount
        )
    }
}

private extension CoinTrackingRow {

    static func makeWithdrawal(
        ico: BlockstackICO,
        payout: BlockstackVestedPayout
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: payout.amount,
            sellCurrency: Blockstack.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: Self.makeComment(),
            date: payout.timestamp
        )
    }

    static func makeTrade(
        ico: BlockstackICO,
        totalPayoutAmount: Decimal
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .trade,
            buyAmount: totalPayoutAmount,
            buyCurrency: Blockstack.ticker,
            sellAmount: ico.contributionAmount,
            sellCurrency: ico.contributionCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: Self.makeComment(),
            date: ico.timestamp
        )
    }

    static func makeDeposit(
        address: String,
        payout: BlockstackVestedPayout
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: payout.amount,
            buyCurrency: Blockstack.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Blockstack \(address.prefix(8)).",
            group: "",
            comment: Self.makeComment(),
            date: payout.timestamp
        )
    }
}
