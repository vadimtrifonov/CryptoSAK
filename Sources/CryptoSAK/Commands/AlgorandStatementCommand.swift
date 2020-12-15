import Algorand
import AlgorandAlgoExplorer
import ArgumentParser
import CoinTracking
import Combine
import Foundation

struct AlgorandStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "algorand-statement")

    @Argument(help: "Algorand address")
    var address: String

    @Option(name: .customLong("known-transactions"), help: "Path to a CSV file with a list of known transactions")
    var knownTransactionsPath: String?

    @Option(help: "Oldest date from which transactions will be exported")
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let knownTransactions = try knownTransactionsPath
            .map(FileManager.default.readLines(atPath:))
            .map(KnownTransactionsCSV.makeTransactions) ?? []

        Self.exportAlgorandStatement(
            address: address,
            transactionsPublisher: AlgoExplorerGateway().fetchTransactions(address: address, startDate: startDate)
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { statement in
            do {
                print(statement.balance)
                try FileManager.default.writeCSV(
                    rows: statement.toCoinTrackingRows(knownTransactions: knownTransactions),
                    filename: "AlgorandStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension AlgorandStatementCommand {

    static func exportAlgorandStatement(
        address: String,
        transactionsPublisher: AnyPublisher<[AlgorandTransaction], Error>
    ) -> AnyPublisher<AlgorandStatement, Error> {
        transactionsPublisher
            .map({ AlgorandStatement(address: address, transactions: $0) })
            .eraseToAnyPublisher()
    }
}

extension AlgorandStatement {

    func toCoinTrackingRows(knownTransactions: [KnownTransaction]) throws -> [CoinTrackingRow] {
        let incoming = incomingTransactions.map { transaction in
            CoinTrackingRow.makeDeposit(transaction: transaction, knownTransactions: knownTransactions)
        }
        let outgoing = outgoingTransactions.map { transaction in
            CoinTrackingRow.makeWithdrawal(transaction: transaction, knownTransactions: knownTransactions)
        }

        let rows = try incoming + outgoing
            + closeTransactions.map(CoinTrackingRow.makeClose)
            + feeIncuringTransactions.map(CoinTrackingRow.makeFee)
            + incomingRewards.map(CoinTrackingRow.makeDepositReward)
            + outgoingRewards.map(CoinTrackingRow.makeWithdrawalReward)
            + closeRewards.map(CoinTrackingRow.makeCloseReward)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeDeposit(
        transaction: AlgorandTransaction,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.receiverNameForCoinTracking,
            group: "",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        ).applyOverride(
            from: knownTransactions,
            withTransactionID: transaction.id,
            makeCommentForCoinTracking: transaction.makeCommentForCoinTracking
        )
    }

    static func makeWithdrawal(
        transaction: AlgorandTransaction,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Algorand.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.senderNameForCoinTracking,
            group: "",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        ).applyOverride(
            from: knownTransactions,
            withTransactionID: transaction.id,
            makeCommentForCoinTracking: transaction.makeCommentForCoinTracking
        )
    }

    static func makeFee(transaction: AlgorandTransaction) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: Algorand.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.senderNameForCoinTracking,
            group: "Fee",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        )
    }

    static func makeClose(transaction: AlgorandTransaction) throws -> CoinTrackingRow {
        try self.init(
            type: .incoming(.otherIncome),
            buyAmount: transaction.getClose().amount,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.closeReceiverNameForCoinTracking(),
            group: "Close",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        )
    }

    static func makeDepositReward(transaction: AlgorandTransaction) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: transaction.receiverRewards,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.receiverNameForCoinTracking,
            group: "Reward",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        )
    }

    static func makeWithdrawalReward(transaction: AlgorandTransaction) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: transaction.senderRewards,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.senderNameForCoinTracking,
            group: "Reward",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        )
    }

    static func makeCloseReward(transaction: AlgorandTransaction) throws -> CoinTrackingRow {
        try self.init(
            type: .incoming(.staking),
            buyAmount: transaction.getClose().rewards,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.closeReceiverNameForCoinTracking(),
            group: "Reward",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp
        )
    }
}

extension AlgorandTransaction {

    var senderNameForCoinTracking: String {
        "Algorand \(sender.prefix(8))."
    }

    var receiverNameForCoinTracking: String {
        "Algorand \(receiver.prefix(8))."
    }

    func closeReceiverNameForCoinTracking() throws -> String {
        try "Algorand \(getClose().remainderReceiver.prefix(8))."
    }

    func getClose() throws -> Close {
        guard let close = close else {
            throw "Expected to find Close details in transaction with ID: \(id)"
        }
        return close
    }

    func makeCommentForCoinTracking(comment: String = "") -> String {
        "Export. \(comment.formattedForCoinTrackingComment)Transaction: \(id)"
    }
}
