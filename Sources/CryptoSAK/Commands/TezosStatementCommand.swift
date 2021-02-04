import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Networking
import Tezos
import TezosTzStats

struct TezosStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "tezos-statement",
        abstract: "Export Tezos operations",
        discussion: "Takes into account Tezos account activation, delegation rewards and fees"
    )

    @Argument(help: "Tezos account")
    var account: String

    @Option(
        name: .customLong("delegate-list"),
        help: .init(
            "Path to a CSV file with a list of delegate payout accounts (for detection of baking rewards)",
            discussion: """
            - No header row
            - Format: <delegate-payout-account>,<delegate-name>
            """
        )
    )
    var delegateListPath: String?

    @Option(name: .customLong("known-transactions"), help: .knownTransactions)
    var knownTransactionsPath: String?

    @Option(help: .startDate(eventsName: "operations"))
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let delegateAccounts = try delegateListPath
            .map(FileManager.default.readLines(atPath:))?
            .compactMap { row in
                row.split(separator: ",").map(String.init).first
            } ?? []

        let knownTransactions = try knownTransactionsPath
            .map(FileManager.default.readLines(atPath:))
            .map(KnownTransactionsCSV.makeTransactions) ?? []

        Self.exportTezosStatement(
            operationsPublisher: TzStatsTezosGateway().fetchOperations(account: account, startDate: startDate),
            account: account,
            delegateAccounts: delegateAccounts
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
                    filename: "TesosStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func exportTezosStatement(
        operationsPublisher: AnyPublisher<TezosOperationGroup, Error>,
        account: String,
        delegateAccounts: [String]
    ) -> AnyPublisher<TezosStatement, Error> {
        operationsPublisher
            .map { operations in
                let statement = TezosStatement(
                    operations: operations,
                    account: account,
                    delegateAccounts: delegateAccounts
                )

                print("Transactions count: \(statement.transactions.all.count)")
                print("Transactions start: \(String(describing: statement.transactions.all.last?.timestamp))")
                print("Transactions end: \(String(describing: statement.transactions.all.first?.timestamp))")
                print("Delegations count: \(statement.successfulDelegations.count)")
                print("Delegations start: \(String(describing: statement.successfulDelegations.last?.timestamp))")
                print("Delegations end: \(String(describing: statement.successfulDelegations.first?.timestamp))")

                return statement
            }
            .eraseToAnyPublisher()
    }
}

extension TezosStatement {

    func toCoinTrackingRows(knownTransactions: [KnownTransaction]) -> [CoinTrackingRow] {
        var rows = transactions.delegationRewards.map(CoinTrackingRow.makeDelegationReward)
            + transactions.otherIncoming.map(CoinTrackingRow.makeDeposit)
            + transactions.outgoing.map(CoinTrackingRow.makeWithdrawal)
            + feeIncuringOperations.map(CoinTrackingRow.makeFee)

        if let accountActivation = accountActivation {
            rows.append(CoinTrackingRow.makeAccountActivation(operation: accountActivation))
        }

        return rows.overriden(with: knownTransactions).sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeAccountActivation(operation: TezosOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: operation.amount,
            buyCurrency: Tezos.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.senderNameForCoinTracking,
            group: "",
            comment: Self.makeComment(
                "Account activation",
                eventName: "Operation",
                eventID: operation.operationHash
            ),
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeDelegationReward(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: operation.amount,
            buyCurrency: Tezos.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.receiverNameForCoinTracking,
            group: "Delegation",
            comment: Self.makeComment(eventName: "Operation", eventID: operation.operationHash),
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeDeposit(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: operation.amount,
            buyCurrency: Tezos.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.receiverNameForCoinTracking,
            group: "",
            comment: Self.makeComment(eventName: "Operation", eventID: operation.operationHash),
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeWithdrawal(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: operation.amount,
            sellCurrency: Tezos.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: operation.senderNameForCoinTracking,
            group: "",
            comment: Self.makeComment(eventName: "Operation", eventID: operation.operationHash),
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeFee(operation: TezosOperation) -> CoinTrackingRow {
        let totalFee = operation.fee + operation.burn

        return self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: totalFee,
            sellCurrency: Tezos.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: operation.senderNameForCoinTracking,
            group: "Fee",
            comment: Self.makeComment(eventName: "Operation", eventID: operation.operationHash),
            date: operation.timestamp
        )
    }
}

extension TezosTransactionOperation {

    var receiverNameForCoinTracking: String {
        "Tezos \(receiver.prefix(8))."
    }
}

extension TezosOperation {

    var senderNameForCoinTracking: String {
        "Tezos \(sender.prefix(8))."
    }
}
