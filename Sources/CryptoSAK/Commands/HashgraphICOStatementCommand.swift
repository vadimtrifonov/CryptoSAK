import ArgumentParser
import CoinTracking
import Combine
import Foundation
import FoundationExtensions
import Hashgraph
import HashgraphDragonGlass
import Networking

struct HashgraphICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "hashgraph-ico-statement",
        abstract: "Export Hasgraph ICO trade and payout transactions",
        shouldDisplay: false
    )

    @Argument(help: "Hashgraph account ID")
    var account: String

    @Argument(help: "Path to a JSON file with the information about ICO")
    var inputPath: String

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let ico = try Self.decodeHashgraphICOJSON(path: inputPath)

        DragonGlassHashgraphGateway(accessKey: Config.dragonGlassAccessKey).fetchHashgraphTransactions(
            account: account,
            startDate: .distantPast
        )
        .map { transactions in
            Self.exportICOTransactions(account: self.account, ico: ico, transactions: transactions)
        }
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { rows in
            do {
                try CoinTrackingCSVEncoder().encode(rows: rows, filename: "HashgraphICOStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func decodeHashgraphICOJSON(path: String) throws -> HashgraphICO {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(HashgraphICO.self, from: data)
    }
}

struct HashgraphICO: Decodable {
    let icoName: String
    let contributionAmount: Decimal
    let contributionCurrency: String
    let senderAccountID: String
    @CustomCoded<ISO8601> var timestamp: Date
}

extension HashgraphICOStatementCommand {

    static func exportICOTransactions(
        account: String,
        ico: HashgraphICO,
        transactions: [HashgraphTransaction]
    ) -> [CoinTrackingRow] {
        let incomingTransactions = HashgraphStatement(
            account: account,
            transactions: transactions
        ).incomingTransactions

        return makeICOCoinTrackingRows(ico: ico, incomingTransactions: incomingTransactions)
            .sorted(by: >)
    }

    static func makeICOCoinTrackingRows(
        ico: HashgraphICO,
        incomingTransactions: [HashgraphTransaction]
    ) -> [CoinTrackingRow] {
        let payoutTransactions = incomingTransactions.filter { transaction in
            transaction.senderID.lowercased() == ico.senderAccountID.lowercased()
        }

        let payoutTransactionRows = payoutTransactions.map { transaction in
            CoinTrackingRow.makeWithdrawal(ico: ico, transaction: transaction)
        }

        let totalPayoutAmount = payoutTransactions.reduce(0, { $0 + $1.amount })
        let tradeRow = CoinTrackingRow.makeTrade(ico: ico, totalPayoutAmount: totalPayoutAmount)

        return (payoutTransactionRows + [tradeRow]).sorted(by: >)
    }
}

extension CoinTrackingRow {

    static func makeWithdrawal(ico: HashgraphICO, transaction: HashgraphTransaction) -> CoinTrackingRow {
        .init(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Hashgraph.symbol,
            fee: 0,
            feeCurrency: "",
            exchange: ico.icoName,
            group: "",
            comment: Self.makeComment(eventID: transaction.readableTransactionID),
            date: transaction.consensusTime
        )
    }

    static func makeTrade(
        ico: HashgraphICO,
        totalPayoutAmount: Decimal
    ) -> CoinTrackingRow {
        .init(
            type: .trade,
            buyAmount: totalPayoutAmount,
            buyCurrency: Hashgraph.symbol,
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
}
