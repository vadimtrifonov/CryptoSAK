import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Networking
import Tezos
import TzStats

struct TezosStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "tezos-statement")

    @Argument(help: "Tezos account")
    var account: String

    @Option(name: .customLong("delegate-list"), help: "Path to a CSV file with a list of delegate payout accounts (for detection of baking rewards)")
    var delegateListPath: String?

    @Option(default: Date.distantPast, help: "Oldest date from which operations will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let rows = try delegateListPath.map(File.read(path:)) ?? []
        let delegateAccounts = rows.compactMap { row in
            row.split(separator: ",").map(String.init).first
        }

        Self.exportTezosStatement(
            operationsPublisher: TzStatsGateway().fetchOperations(account: account, startDate: startDate),
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
                try File.write(rows: statement.toCoinTrackingRows(), filename: "TesosStatement")
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

    func toCoinTrackingRows() -> [CoinTrackingRow] {
        var rows = transactions.delegationRewards.map(CoinTrackingRow.makeDelegationReward)
            + transactions.otherIncoming.map(CoinTrackingRow.makeDeposit)
            + transactions.outgoing.map(CoinTrackingRow.makeWithdrawal)
            + feeIncuringOperations.map(CoinTrackingRow.makeFee)

        if let accountActivation = accountActivation {
            rows.append(CoinTrackingRow.makeAccountActivation(operation: accountActivation))
        }

        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeAccountActivation(operation: TezosOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: operation.amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.senderNameForCoinTracking,
            group: "",
            comment: "Export. Account activation. Operation: \(operation.operationHash)",
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeDelegationReward(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: operation.amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.receiverNameForCoinTracking,
            group: "Delegation",
            comment: "Export. Operation: \(operation.operationHash)",
            date: operation.timestamp,
            transactionID: operation.operationHash
        )
    }

    static func makeDeposit(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.deposit),
            buyAmount: operation.amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.receiverNameForCoinTracking,
            group: "",
            comment: "Export. Operation: \(operation.operationHash)",
            date: operation.timestamp,
            transactionID: ""
        )
    }

    static func makeWithdrawal(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: operation.amount,
            sellCurrency: "XTZ",
            fee: 0,
            feeCurrency: "",
            exchange: operation.senderNameForCoinTracking,
            group: "",
            comment: "Export. Operation: \(operation.operationHash)",
            date: operation.timestamp,
            transactionID: ""
        )
    }

    static func makeFee(operation: TezosOperation) -> CoinTrackingRow {
        let totalFee = operation.fee + operation.burn

        return self.init(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: totalFee,
            sellCurrency: "XTZ",
            fee: totalFee,
            feeCurrency: "XTZ",
            exchange: operation.senderNameForCoinTracking,
            group: "Fee",
            comment: "Export. Operation: \(operation.operationHash)",
            date: operation.timestamp,
            transactionID: ""
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
