import AlgoExplorer
import Algorand
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

    @Option(default: Date.distantPast, help: "Oldest date from which transactions will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let rows = try knownTransactionsPath.map(File.read(path:)) ?? []
        let knownTransactions = try rows.map(KnownAlgorandTransaction.init)

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
                try File.write(
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

struct KnownAlgorandTransaction {
    let transactionID: String
    let type: CoinTrackingRow.TransactionType
    let description: String
}

private extension KnownAlgorandTransaction {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        let numberOfColumns = 3
        guard columns.count == numberOfColumns else {
            throw "Expected \(numberOfColumns) columns, got \(columns)"
        }

        guard let type = CoinTrackingRow.TransactionType(rawValue: columns[1]) else {
            throw "Unknown transaction type: \(columns[1]), known types: \(CoinTrackingRow.TransactionType.allCases.map(\.rawValue))"
        }

        self.init(
            transactionID: columns[0],
            type: type,
            description: columns[2]
        )
    }
}

extension AlgorandStatement {

    func toCoinTrackingRows(knownTransactions: [KnownAlgorandTransaction]) throws -> [CoinTrackingRow] {
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
        knownTransactions: [KnownAlgorandTransaction]
    ) -> CoinTrackingRow {
        let knownTransaction = knownTransactions.first(where: { $0.transactionID == transaction.id })

        return self.init(
            type: knownTransaction?.type ?? .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Algorand.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.receiverNameForCoinTracking,
            group: "",
            comment: transaction.makeCommentForCoinTracking(description: knownTransaction?.description),
            date: transaction.timestamp,
            transactionID: ""
        )
    }

    static func makeWithdrawal(
        transaction: AlgorandTransaction,
        knownTransactions: [KnownAlgorandTransaction]
    ) -> CoinTrackingRow {
        let knownTransaction = knownTransactions.first(where: { $0.transactionID == transaction.id })

        return self.init(
            type: knownTransaction?.type ?? .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Algorand.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.senderNameForCoinTracking,
            group: "",
            comment: transaction.makeCommentForCoinTracking(description: knownTransaction?.description),
            date: transaction.timestamp,
            transactionID: ""
        )
    }

    static func makeFee(transaction: AlgorandTransaction) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: Algorand.ticker,
            fee: transaction.fee,
            feeCurrency: Algorand.ticker,
            exchange: transaction.senderNameForCoinTracking,
            group: "Fee",
            comment: transaction.makeCommentForCoinTracking(),
            date: transaction.timestamp,
            transactionID: ""
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
            date: transaction.timestamp,
            transactionID: ""
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
            date: transaction.timestamp,
            transactionID: ""
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
            date: transaction.timestamp,
            transactionID: ""
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
            date: transaction.timestamp,
            transactionID: ""
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

    func makeCommentForCoinTracking(description: String? = nil) -> String {
        var explanation = ""

        if let description = description?.trimmingCharacters(in: .whitespaces) {
            explanation = description.hasSuffix(".") ? description + " " : description + ". "
        }

        return "Export. \(explanation)Transaction: \(id)"
    }
}
