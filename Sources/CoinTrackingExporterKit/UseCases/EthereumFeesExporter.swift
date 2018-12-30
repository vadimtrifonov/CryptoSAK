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
        var results = [Result<[Transaction]>]()
        let group = DispatchGroup()
        
        [etherscanGateway.fetchNormalTransactions,
         etherscanGateway.fetchTokenTransactions].forEach { fetch in
            group.enter()
            fetch(address) { result in
                results.append(result)
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            do {
                let rows = try results
                    .flatMap({ try $0.unwrap() })
                    .filter({ $0.from.lowercased() == address.lowercased() })
                    .uniqueElements
                    .sorted(by: >)
                    .map(CoinTrackingRow.init)
                handler(.success(rows))
            } catch {
                return handler(.failure(error))
            }
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
