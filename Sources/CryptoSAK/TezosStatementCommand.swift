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

        tezosGateway.fetchOperations(account: account, startDate: startDate)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
                exit(0)
            }, receiveValue: { operations in
                do {
                    print("Final count: \(operations.count)")
                    print("Final last operation date: \(String(describing: operations.last?.timestamp))")

                    let statement = TezosStatement(
                        operations: operations,
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
        let rows = delegationRewards.map(CoinTrackingRow.makeDelegationReward)
            + otherIncomingOperations.map(CoinTrackingRow.makeDeposit)
            + successfulOutgoingOperations.map(CoinTrackingRow.makeWithdrawal)
            + feeIncuringOperations.map(CoinTrackingRow.makeFee)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {
    static func makeDelegationReward(operation: TezosOperation) -> CoinTrackingRow {
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

    static func makeDeposit(operation: TezosOperation) -> CoinTrackingRow {
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

    static func makeWithdrawal(operation: TezosOperation) -> CoinTrackingRow {
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
            exchange: operation.source.nameForCoinTracking,
            group: "Fee",
            comment: "Export. Operation: \(operation.hash)",
            date: operation.timestamp
        )
    }
}

extension TezosOperation.Destination {
    var nameForCoinTracking: String {
        return "Tezos \(account.prefix(8))."
    }
}

extension TezosOperation.Source {
    var nameForCoinTracking: String {
        return "Tezos \(account.prefix(8))."
    }
}
