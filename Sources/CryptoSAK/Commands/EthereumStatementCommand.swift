import ArgumentParser
import CoinTracking
import Combine
import Ethereum
import EthereumEtherscan
import Foundation

struct EthereumStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "ethereum-statement")

    @Argument(help: "Etherium address")
    var address: String

    @Option(default: Date.distantPast, help: "Oldest date from which transactions will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let gateway = makeEthereumGateway()

        Publishers.Zip(
            gateway.fetchNormalTransactions(address: address, startDate: startDate),
            gateway.fetchInternalTransactions(address: address, startDate: startDate)
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { [address] normalTransactions, internalTransactions in
            do {
                let statement = EthereumStatement(
                    normalTransactions: normalTransactions,
                    internalTransactions: internalTransactions,
                    address: address
                )
                print(statement.balance)
                try File.write(rows: statement.toCoinTrackingRows(), filename: "EthereumStatement")
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
        CoinTrackingRow(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: Ethereum.ticker,
            fee: transaction.fee,
            feeCurrency: Ethereum.ticker,
            exchange: transaction.sourceNameForCoinTracking,
            group: "Fee",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: ""
        )
    }

    static func makeNormalDeposit(transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Ethereum.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.destinationNameForCoinTracking,
            group: "",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: transaction.hash
        )
    }

    static func makeInternalDeposit(transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Ethereum.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.destinationNameForCoinTracking,
            group: "Internal",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: transaction.hash
        )
    }

    static func makeNormalWithdrawal(transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Ethereum.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: transaction.hash
        )
    }

    static func makeInternalWithdrawal(transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: Ethereum.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "Internal",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: transaction.hash
        )
    }
}

private extension EthereumTransaction {
    var sourceNameForCoinTracking: String {
        "Ethereum \(from.prefix(8))."
    }

    var destinationNameForCoinTracking: String {
        "Ethereum \(to.prefix(8))."
    }
}
