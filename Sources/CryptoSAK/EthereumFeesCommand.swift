import Foundation
import EthereumKit
import EtherscanKit
import CoinTrackingKit

struct EthereumFeesCommand {
    let gateway: EthereumGateway
    
    func execute(address: String) throws {
        gateway.fetchNormalTransactions(address: address) { result in
            do {
                let transactions = try Self.outgoingTransactions(
                    transactions: result.unwrap(),
                    address: address
                )
                let rows = transactions.map(CoinTrackingRow.init)
                try write(rows: rows, filename: String(describing: self))
                print("Total fees: \(transactions.reduce(0) { $0 + $1.fee })")
                exit(0)
            } catch {
                print(error)
            }
        }

        RunLoop.main.run()
    }

    static func outgoingTransactions(
        transactions: [EthereumTransaction],
        address: String
    ) -> [EthereumTransaction] {
        return Set(transactions)
            .filter { $0.isOutgoing(address: address) }
            .sorted(by: >)
    }
}

private extension CoinTrackingRow {
    init(transaction: EthereumTransaction) {
        self.init(
            type: .outgoing(.lost),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: "ETH",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "Fee",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }
}

private extension EthereumTransaction {
    var sourceNameForCoinTracking: String {
        return "Ethereum \(from.prefix(8))."
    }
}
