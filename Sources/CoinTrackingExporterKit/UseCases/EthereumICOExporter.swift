import Foundation

public struct ICO {
    let name: String
    let tokenSymbol: String
    let contributionHashes: [String]
    
    public init(
        name: String,
        tokenSymbol: String,
        contributionHashes: [String]
    ) {
        self.name = name
        self.tokenSymbol = tokenSymbol
        self.contributionHashes = contributionHashes
    }
}

public protocol EthereumICOExporter {
    func export(ico: ICO, handler: @escaping (Result<[CoinTrackingRow]>) -> Void)
}

public class EthereumICOExporterImpl: EthereumICOExporter {
    private let etherscanGateway: EtherscanGateway
    
    public init(etherscanGateway: EtherscanGateway) {
        self.etherscanGateway = etherscanGateway
    }
    
    public func export(ico: ICO, handler: @escaping (Result<[CoinTrackingRow]>) -> Void) {
        var results = [Result<Transaction>]()
        let group = DispatchGroup()
        
        ico.contributionHashes.forEach { hash in
            group.enter()
            etherscanGateway.fetchTransaction(hash: hash) { result in
                results.append(result)
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            do {
                let transactions = try results.map({ try $0.unwrap() })
                let address = transactions.first?.from ?? ""
                let totalEtherAmount = transactions.reduce(0, { $0 + $1.amount })
                let depositRows = transactions.map {
                    CoinTrackingRow(
                        type: .deposit,
                        buyAmount: $0.amount,
                        buyCurrency: "ETH",
                        sellAmount: 0,
                        sellCurrency: "",
                        fee: 0,
                        feeCurrency: "",
                        exchange: ico.name,
                        group: "",
                        comment: "Export \($0.hash)",
                        date: $0.date
                    )
                }
                
                self?.fetchTokenWithdrawalTransactions(address: address, ico: ico) { result in
                    let result = result.map { transactions -> [CoinTrackingRow] in
                        let totalTokenAmount = transactions.reduce(0, { $0 + $1.amount })
                        
                        let tradeRow = transactions.first.map { transaction in
                            [CoinTrackingRow(
                                type: .trade,
                                buyAmount: totalTokenAmount,
                                buyCurrency: transaction.tokenSymbol,
                                sellAmount: totalEtherAmount,
                                sellCurrency: "ETH",
                                fee: 0,
                                feeCurrency: "",
                                exchange: ico.name,
                                group: "",
                                comment: "Export",
                                date: transaction.date
                            )]
                        } ?? []
                        
                        let withdrawalRows = transactions.map { transaction in
                            CoinTrackingRow(
                                type: .withdrawal,
                                buyAmount: 0,
                                buyCurrency: "",
                                sellAmount: transaction.amount,
                                sellCurrency: transaction.tokenSymbol,
                                fee: 0,
                                feeCurrency: "",
                                exchange: ico.name,
                                group: "",
                                comment: "Export \(transaction.hash)",
                                date: transaction.date
                            )
                        }
                        
                        return depositRows + tradeRow + withdrawalRows
                    }
                    handler(result)
                }
            } catch {
                return handler(.failure(error))
            }
        }
    }
    
    private func fetchTokenWithdrawalTransactions(
        address: String,
        ico: ICO,
        handler: @escaping (Result<[TokenTransaction]>) -> Void
    ) {
        etherscanGateway.fetchTokenTransactions(address: address) { result in
            do {
                let transactions = try result.unwrap()
                
                let firstWithdrawal = transactions
                    .filter({ $0.to.lowercased() == address.lowercased() })
                    .sorted(by: <)
                    .first(where: { $0.tokenSymbol.uppercased() == ico.tokenSymbol.uppercased() })
                
                let allWithdrawals = transactions
                    .filter({ $0.from.lowercased() == firstWithdrawal?.from.lowercased() })
                    .sorted(by: <)
                
                handler(.success(allWithdrawals))
            } catch {
                handler(.failure(error))
            }
        }
    }
}
