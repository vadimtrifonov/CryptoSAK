import Foundation

public protocol EthereumICOExporter {
    func export(ico: ICO, handler: @escaping (Result<[CoinTrackingRow]>) -> Void)
}

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
                let total = transactions.reduce(0, { $0 + $1.value })
                let rows = transactions.map {
                    CoinTrackingRow(
                        type: .deposit,
                        buyAmount: $0.value,
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
                
                self?.fetchTokensDepositTransaction(address: address, ico: ico) { result in
                    let result = result.map {
                        $0.map { transaction in
                            return rows + [
                                CoinTrackingRow(
                                    type: .trade,
                                    buyAmount: transaction.value,
                                    buyCurrency: transaction.tokenSymbol ?? "",
                                    sellAmount: total,
                                    sellCurrency: "ETH",
                                    fee: 0,
                                    feeCurrency: "",
                                    exchange: ico.name,
                                    group: "",
                                    comment: "Export",
                                    date: transaction.date
                                ),
                                CoinTrackingRow(
                                    type: .withdrawal,
                                    buyAmount: 0,
                                    buyCurrency: "",
                                    sellAmount: transaction.value,
                                    sellCurrency: transaction.tokenSymbol ?? "",
                                    fee: 0,
                                    feeCurrency: "",
                                    exchange: ico.name,
                                    group: "",
                                    comment: "Export \(transaction.hash)",
                                    date: transaction.date
                                )
                            ]
                        } ?? []
                    }
                    handler(result)
                }
            } catch {
                return handler(.failure(error))
            }
        }
    }
    
    private func fetchTokensDepositTransaction(address: String, ico: ICO, handler: @escaping (Result<Transaction?>) -> Void) {
        etherscanGateway.fetchTokenTransactions(address: address) { result in
            do {
                let transaction = try result.unwrap()
                    .filter({ $0.to.lowercased() == address.lowercased() })
                    .sorted(by: <)
                    .first(where: { $0.tokenSymbol?.uppercased() == ico.tokenSymbol.uppercased() })
                handler(.success(transaction))
            } catch {
                handler(.failure(error))
            }
        }
    }
}

