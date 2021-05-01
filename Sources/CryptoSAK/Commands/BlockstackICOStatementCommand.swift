import ArgumentParser
import CodableCSV
import CoinTracking
import Foundation
import FoundationExtensions

struct BlockstackICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "blockstack-ico-statement",
        abstract: "Convert Blockstack ICO token unlocking information",
        shouldDisplay: false
    )

    @Argument(help: "Blockstack address")
    var address: String

    @Argument(help: "Path to a JSON file with the information about ICO")
    var icoJSONPath: String

    @Argument(help: "Path to a CSV file with the Stacks cumulative vested payouts")
    var payoutsCSVPath: String

    func run() throws {
        let ico = try Self.decodeBlockstackICOJSON(path: icoJSONPath)
        let payoutRows = try Self.decodeBlockstackVestedPayoutsCSV(path: payoutsCSVPath)

        let payouts = Self.toNonCumulativePayouts(rows: payoutRows)
        let icoRows = Self.makeICOCoinTrackingRows(ico: ico, payouts: payouts)
        let depositRows = payouts.map({ CoinTrackingRow.makeDeposit(address: address, payout: $0) })
        let rows = (icoRows + depositRows).sorted(by: >)

        try CoinTrackingCSVEncoder().encode(rows: rows, filename: "BlockstackICOStatementCommand")
    }

    static func decodeBlockstackICOJSON(path: String) throws -> BlockstackICO {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(BlockstackICO.self, from: data)
    }

    static func decodeBlockstackVestedPayoutsCSV(path: String) throws -> [BlockstackVestedPayoutRow] {
        try CSVDecoder().decode([BlockstackVestedPayoutRow].self, from: URL(fileURLWithPath: path))
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
    static let symbol = "STX2" // CoinTracking symbol
    static let microStacksInStack = Decimal(pow(10, 6))
}

struct BlockstackVestedPayout {
    let timestamp: Date
    let amount: Decimal
}

struct BlockstackICO: Decodable {
    let icoName: String
    let contributionAmount: Decimal
    let contributionCurrency: String
    @CustomCoded<ISO8601> var timestamp: Date
}

struct ConvertMicroStacksToStacks: CustomDecoding {

    static func decode(from decoder: Decoder) throws -> Decimal {
        let microStackAmount = try UInt(from: decoder)
        return Decimal(microStackAmount) / Blockstack.microStacksInStack
    }
}

struct BlockstackVestedPayoutRow: Decodable {
    @CustomCoded<SecondsSince1970> var timestamp: Date
    @CustomCoded<ConvertMicroStacksToStacks> var cumulativeAmount: Decimal

    enum CodingKeys: Int, CodingKey {
        case timestamp
        case cumulativeAmount
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
            sellCurrency: Blockstack.symbol,
            fee: 0,
            feeCurrency: "",
            exchange: ico.icoName,
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
            buyCurrency: Blockstack.symbol,
            sellAmount: ico.contributionAmount,
            sellCurrency: ico.contributionCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: ico.icoName,
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
            buyCurrency: Blockstack.symbol,
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
