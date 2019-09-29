import CoinTrackingKit
import Combine
import Foundation
import HTTPClient
import TezosKit
import TzScanKit

struct TezosStatementCommand {
    func execute(account: String, delegateListPath: String, startDate: Date) throws {
        var subscriptions = Set<AnyCancellable>()

        let baseURL: URL = "https://api6.tzscan.io"
        let urlSession = URLSession(configuration: .default)
        let httpClient = DefaultHTTPClient(baseURL: baseURL, urlSession: urlSession, apiKey: "none")
        let tezosGateway = TzScanGateway(httpClient: httpClient)

        let rows = delegateListPath.isEmpty ? [] : try CSV.read(path: delegateListPath)
        let delegateAccounts = rows.compactMap { row in
            row.split(separator: ",").map(String.init).first
        }

        Publishers.Zip(
            tezosGateway.fetchTransactionOperations(account: account, startDate: startDate),
            tezosGateway.fetchDelegationOperations(account: account, startDate: startDate)
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            exit(0)
        }, receiveValue: { transactions, delegations in
            do {
                print("Transactions count: \(transactions.count)")
                print("Transactions starting date: \(String(describing: transactions.last?.timestamp))")
                print("Delegations count: \(delegations.count)")
                print("Delegations starting date: \(String(describing: delegations.last?.timestamp))")

                let statement = TezosStatement(
                    transactions: transactions,
                    delegations: delegations,
                    account: account,
                    delegateAccounts: delegateAccounts
                )

                print(statement.balance)
                try write(rows: statement.toCoinTrackingRows(), filename: "TesosStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
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
            exchange: operation.destination.nameForCoinTracking,
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
            exchange: operation.destination.nameForCoinTracking,
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
            exchange: operation.source.nameForCoinTracking,
            group: "",
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
        )
    }

    static func makeFee(operation: TezosOperation) -> CoinTrackingRow {
        self.init(
            type: .outgoing(.lost),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: operation.fee,
            sellCurrency: "XTZ",
            fee: operation.fee,
            feeCurrency: "XTZ",
            exchange: operation.sourceNameForCoinTracking,
            group: "Fee",
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
        )
    }
}

extension TezosTransactionOperation.Destination {
    var nameForCoinTracking: String {
        return "Tezos \(account.prefix(8))."
    }
}

extension TezosTransactionOperation.Source {
    var nameForCoinTracking: String {
        return "Tezos \(account.prefix(8))."
    }
}

extension TezosOperation {
    var sourceNameForCoinTracking: String {
        return "Tezos \(sourceAccount.prefix(8))."
    }
}
