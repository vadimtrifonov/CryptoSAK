import CoinTrackingKit
import Combine
import EthereumKit
import EtherscanKit
import Foundation

struct EthereumStatementCommand {
    let gateway: EthereumGateway

    func execute(address: String, startDate: Date) throws {
        var subscriptions = Set<AnyCancellable>()

        Publishers.Zip(
            gateway.fetchNormalTransactions(address: address, startDate: startDate),
            gateway.fetchInternalTransactions(address: address, startDate: startDate)
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            exit(0)
        }, receiveValue: { normalTransactions, internalTransactions in
            do {
                let statement = EthereumStatement(
                    normalTransactions: normalTransactions,
                    internalTransactions: internalTransactions,
                    address: address
                )
                print(statement.balance)
                try write(rows: statement.toCoinTrackingRows(), filename: "EthereumStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

private extension EthereumStatement {
    func toCoinTrackingRows() -> [CoinTrackingRow] {
        let rows = incomingNormalTransactions.map(CoinTrackingRow.makeNormalDeposit)
            + incomingInternalTransactions.map(CoinTrackingRow.makeInternalDeposit)
            + successfulOutgoingNormalTransactions.map(CoinTrackingRow.makeNormalWithdrawal)
            + successfulOutgoingInternalTransactions.map(CoinTrackingRow.makeInternalWithdrawal)
            + feeIncurringTransactions.map(CoinTrackingRow.makeFee)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {
    static func makeFee(transaction: EthereumTransaction) -> CoinTrackingRow {
        return CoinTrackingRow(
            type: .outgoing(.lost),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: "ETH",
            fee: transaction.fee,
            feeCurrency: "ETH",
            exchange: transaction.sourceNameForCoinTracking,
            group: "Fee",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }

    static func makeNormalDeposit(transaction: EthereumTransaction) -> CoinTrackingRow {
        return CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: "ETH",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.destinationNameForCoinTracking,
            group: "",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }

    static func makeInternalDeposit(transaction: EthereumTransaction) -> CoinTrackingRow {
        return CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: "ETH",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.destinationNameForCoinTracking,
            group: "Internal",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }

    static func makeNormalWithdrawal(transaction: EthereumTransaction) -> CoinTrackingRow {
        return CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: "ETH",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }

    static func makeInternalWithdrawal(transaction: EthereumTransaction) -> CoinTrackingRow {
        return CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: "ETH",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "Internal",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }
}

private extension EthereumTransaction {
    var sourceNameForCoinTracking: String {
        return "Ethereum \(from.prefix(8))."
    }

    var destinationNameForCoinTracking: String {
        return "Ethereum \(to.prefix(8))."
    }
}
