import ArgumentParser
import CoinTracking
import Combine
import Foundation
import FoundationExtensions
import Hashgraph
import HashgraphDragonGlass
import Lambda
import Networking

struct HashgraphStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "hashgraph-statement")

    @Argument(help: "Hashgraph account")
    var account: String

    @Option(default: Date.distantPast, help: " Oldest date from which transactions will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        Self.exportHashgraphStatement(
            account: account,
            hashgraphTransactions: DragonGlass.fetchHashgraphTransactions(
                accessKey: Config.dragonGlassAccessKey,
                account: account,
                startDate: startDate
            )
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { statement in
            do {
                let defaultStartingBalance: Decimal = 5.00005
                print("Incoming sender IDs: \(Dictionary(grouping: statement.incomingTransactions, by: \.senderID).keys)")
                print("Balance: \(statement.balance.balance + defaultStartingBalance)")
                print("Incoming: \(statement.balance.incoming)")
                print("Outgoing: \(statement.balance.successfulOutgoing)")
                print("Account service: \(statement.balance.accountService)")
                print("Fees: \(statement.balance.fees)")

                try FileManager.default.writeCSV(
                    rows: statement.toCoinTrackingRows(),
                    filename: "HashgraphStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension HashgraphStatementCommand {

    static func exportHashgraphStatement(
        account: String,
        hashgraphTransactions: AnyPublisher<[HashgraphTransaction], Error>
    ) -> AnyPublisher<HashgraphStatement, Error> {
        hashgraphTransactions
            .map({ HashgraphStatement(account: account, transactions: $0) })
            .eraseToAnyPublisher()
    }
}

extension HashgraphStatement {
    func toCoinTrackingRows() -> [CoinTrackingRow] {
        let rows = successfulOutgoingTransactions.map(CoinTrackingRow.makeWithdrawal)
            + accountServiceTransactions.map(CoinTrackingRow.makeAccountService)
            + incomingTransactions.map(CoinTrackingRow.makeDeposit)
            + feeIncurringTransactions.map(CoinTrackingRow.makeFee)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeDeposit(transaction: HashgraphTransaction) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Hashgraph.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Hashgraph \(transaction.receiverID)",
            group: "",
            comment: "Export. Transaction: \(transaction.readableTransactionID)",
            date: transaction.consensusTime
        )
    }

    static func makeWithdrawal(transaction: HashgraphTransaction) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Hashgraph.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: "Hashgraph \(transaction.senderID)",
            group: "",
            comment: "Export. Transaction: \(transaction.readableTransactionID)",
            date: transaction.consensusTime
        )
    }

    static func makeAccountService(transaction: HashgraphTransaction) -> CoinTrackingRow {
        let totalAmount = transaction.amount + transaction.fee

        return self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: totalAmount,
            sellCurrency: Hashgraph.ticker,
            fee: transaction.fee,
            feeCurrency: Hashgraph.ticker,
            exchange: "Hashgraph \(transaction.senderID)",
            group: "Account",
            comment: "Export. \(transaction.memo.rawValue). Transaction: \(transaction.readableTransactionID)",
            date: transaction.consensusTime
        )
    }

    static func makeFee(transaction: HashgraphTransaction) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: Hashgraph.ticker,
            fee: transaction.fee,
            feeCurrency: Hashgraph.ticker,
            exchange: "Hashgraph \(transaction.senderID)",
            group: "Fee",
            comment: "Export. Transaction: \(transaction.readableTransactionID)",
            date: transaction.consensusTime
        )
    }
}
