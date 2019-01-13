import Foundation

public protocol EthereumFeesExporter {
    func export(address: String, handler: @escaping (Result<[CoinTrackingRow]>) -> Void)
}

public class EthereumFeesExporterImpl: EthereumFeesExporter {
    let etherscanGateway: EtherscanGateway
    
    public init(etherscanGateway: EtherscanGateway) {
        self.etherscanGateway = etherscanGateway
    }
    
    public func export(address: String, handler: @escaping (Result<[CoinTrackingRow]>) -> Void) {
        etherscanGateway.fetchNormalTransactions(address: address) { result in
            handler(result.map { transactions in
                transactions
                    .distinct
                    .filter({ $0.from.lowercased() == address.lowercased() })
                    .sorted(by: >)
                    .map(CoinTrackingRow.init)
            })
        }
    }
}

private extension CoinTrackingRow {
    
    init(transaction: Transaction) {
        self.init(
            type: .lost,
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.fee,
            sellCurrency: "ETH",
            fee: 0,
            feeCurrency: "",
            exchange: "ETH Transaction",
            group: "",
            comment: "Transaction fee: \(transaction.hash)",
            date: transaction.date
        )
    }
}
