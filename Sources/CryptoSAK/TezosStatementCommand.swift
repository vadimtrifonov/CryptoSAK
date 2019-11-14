import CoinTrackingKit
import Combine
import Foundation
import HTTPClient
import TezosKit
import TzStatsKit

struct TezosStatementCommand {
    static func execute(account: String, delegateListPath: String, startDate: Date) throws {
        var subscriptions = Set<AnyCancellable>()
        let tezosGateway = TzStatsGateway(urlSession: URLSession.shared)

        let rows = delegateListPath.isEmpty ? [] : try File.read(path: delegateListPath)
        let delegateAccounts = rows.compactMap { row in
            row.split(separator: ",").map(String.init).first
        }

        Self.exportTezosStatement(
            transactionsPublisher: tezosGateway.fetchTransactionOperations(account: account, startDate: startDate),
            delegationsPublisher: tezosGateway.fetchDelegationOperations(account: account, startDate: startDate),
            account: account,
            delegateAccounts: delegateAccounts
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            exit(0)
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
        transactionsPublisher: AnyPublisher<[TezosTransactionOperation], Error>,
        delegationsPublisher: AnyPublisher<[TezosDelegationOperation], Error>,
        account: String,
        delegateAccounts: [String]
    ) -> AnyPublisher<TezosStatement, Error> {
        Publishers.Zip(
            transactionsPublisher,
            delegationsPublisher
        )
        .map { transactions, delegations in
            let statement = TezosStatement(
                transactions: transactions,
                delegations: delegations,
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
        let rows = transactions.delegationRewards.map(CoinTrackingRow.makeDelegationReward)
            + transactions.otherIncoming.map(CoinTrackingRow.makeDeposit)
            + transactions.successfulOutgoing.map(CoinTrackingRow.makeWithdrawal)
            + feeIncuringOperations.map(CoinTrackingRow.makeFee)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {
    static func makeDelegationReward(operation: TezosTransactionOperation) -> CoinTrackingRow {
        self.init(
            type: .incoming(.mining),
            buyAmount: operation.amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: operation.receiverNameForCoinTracking,
            group: "Delegation",
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
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
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
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
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
        )
    }

    static func makeFee(operation: TezosOperation) -> CoinTrackingRow {
        let totalFee = operation.fee + operation.burn
        
        return self.init(
            type: .outgoing(.lost),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: totalFee,
            sellCurrency: "XTZ",
            fee: totalFee,
            feeCurrency: "XTZ",
            exchange: operation.senderNameForCoinTracking,
            group: "Fee",
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
        )
    }
}

extension TezosTransactionOperation {
    var receiverNameForCoinTracking: String {
        return "Tezos \(receiver.prefix(8))."
    }
}

extension TezosOperation {
    var senderNameForCoinTracking: String {
        return "Tezos \(sender.prefix(8))."
    }
}
