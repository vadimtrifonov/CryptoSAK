import ArgumentParser
import CoinTracking
import Combine
import DragonGlass
import Foundation
import FoundationExtensions
import Hashgraph
import Lambda
import Networking

struct HashgraphICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "hashgraph-ico-statement")

    @Argument(help: "Hashgraph account")
    var account: String

    @Argument(help: "Path to CSV file with information about ICO")
    var inputPath: String

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try File.read(path: inputPath)
        let icos = try csvRows.map(HashgraphICO.init)

        guard !icos.isEmpty else {
            print("Nothing to export, the file is empty")
            Self.exit()
        }

        DragonGlass.fetchHashgraphTransactions(
            accessKey: Config.dragonGlassAccessKey,
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
                try File.write(
                    rows: rows,
                    filename: "HashgraphICOStatement"
                )
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
}

private extension HashgraphICO {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        let numberOfColumns = 4
        guard columns.count == numberOfColumns else {
            throw "Expected \(numberOfColumns) columns, got \(columns)"
        }

        self.init(
            name: columns[0],
            contributionAmount: try Decimal(string: columns[1]),
            contributionCurrency: columns[2],
            senderAccountID: columns[3]
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

        let totalPayoutAmount = payoutTransactions.reduce(0, { $0 + $1.amount })

        let payoutTransactionRows = payoutTransactions.map { transaction in
            CoinTrackingRow.makeWithdrawal(ico: ico, transaction: transaction)
        }

        let tradeRows = payoutTransactions.map { transaction -> CoinTrackingRow in
            let payoutPercent = transaction.amount / totalPayoutAmount
            let proportionalContributionAmount = ico.contributionAmount * payoutPercent
            return CoinTrackingRow.makeTrade(
                ico: ico,
                transaction: transaction,
                proportionalContributionAmount: proportionalContributionAmount
            )
        }

        return (payoutTransactionRows + tradeRows).sorted(by: >)
    }
}

extension CoinTrackingRow {

    static func makeWithdrawal(ico: HashgraphICO, transaction: HashgraphTransaction) -> CoinTrackingRow {
        self.init(
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
            date: transaction.consensusTime,
            transactionID: "" // CoinTracking considers transaction with the same ID as duplicate, even when one is deposit and another is withdrawal
        )
    }

    static func makeTrade(
        ico: HashgraphICO,
        transaction: HashgraphTransaction,
        proportionalContributionAmount: Decimal
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .trade,
            buyAmount: transaction.amount,
            buyCurrency: Hashgraph.ticker,
            sellAmount: proportionalContributionAmount,
            sellCurrency: ico.contributionCurrency,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export",
            date: transaction.consensusTime,
            transactionID: ""
        )
    }
}
