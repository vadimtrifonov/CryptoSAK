import ArgumentParser
import CoinTracking
import Combine
import Foundation
import FoundationExtensions
import Hashgraph
import HashgraphDragonGlass
import Lambda
import Networking

struct HashgraphICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "hashgraph-ico-statement",
        abstract: "Export Hasgraph ICO trade and payout transactions",
        shouldDisplay: false
    )

    @Argument(help: "Hashgraph account ID")
    var account: String

    @Argument(
        help: .init(
            "Path to a CSV file with the information about ICO",
            discussion: """
            - Each row is a separate ICO (no header row)
            - Format: <ico-name>,<contribution-amount>,<contribution-currency>,<sender-account-ID>,<timestamp>
            - Timestamp format: `YYYY-MM-DDThh:mm:ssTZD`
            """
        )
    )
    var inputPath: String

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try FileManager.default.readLines(atPath: inputPath)
        let icos = try csvRows.map(HashgraphICO.init)

        guard !icos.isEmpty else {
            print("Nothing to export, the file is empty")
            Self.exit()
        }

        DragonGlassHashgraphGateway(accessKey: Config.dragonGlassAccessKey).fetchHashgraphTransactions(
            account: account,
            startDate: .distantPast
        )
        .map { transactions in
            Self.exportICOTransactions(account: self.account, icos: icos, transactions: transactions)
        }
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { rows in
            do {
                try FileManager.default.writeCSV(rows: rows, filename: "HashgraphICOStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

struct HashgraphICO {
    let name: String
    let contributionAmount: Decimal
    let contributionCurrency: String
    let senderAccountID: String
    let timestamp: Date
}

private extension HashgraphICO {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        let numberOfColumns = 5
        guard columns.count == numberOfColumns else {
            throw "Expected \(numberOfColumns) columns, got \(columns)"
        }

        self.init(
            name: columns[0],
            contributionAmount: try Decimal(string: columns[1]),
            contributionCurrency: columns[2],
            senderAccountID: columns[3],
            timestamp: try ISO8601DateFormatter().date(from: columns[4])
        )
    }
}

extension HashgraphICOStatementCommand {

    static func exportICOTransactions(
        account: String,
        icos: [HashgraphICO],
        transactions: [HashgraphTransaction]
    ) -> [CoinTrackingRow] {
        let incomingTransactions = HashgraphStatement(
            account: account,
            transactions: transactions
        ).incomingTransactions

        return icos
            .flatMap({ makeICOCoinTrackingRows(ico: $0, incomingTransactions: incomingTransactions) })
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
            sellCurrency: Hashgraph.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export. Transaction: \(transaction.readableTransactionID)",
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
            buyCurrency: Hashgraph.ticker,
            sellAmount: ico.contributionAmount,
            sellCurrency: ico.contributionCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export",
            date: ico.timestamp
        )
    }
}
