import Foundation
import EthereumKit
import EtherscanKit
import CoinTrackingKit
import FoundationExtensions

public struct ICO {
    public let name: String
    public let tokenSymbol: String
    public let contributionHashes: [String]

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

public class DefaultEthereumICOExporter: EthereumICOExporter {
    private let etherscanGateway: EthereumGateway

    public init(etherscanGateway: EthereumGateway) {
        self.etherscanGateway = etherscanGateway
    }

    public func export(ico: ICO, handler: @escaping (Result<[CoinTrackingRow]>) -> Void) {
        var results = [Result<EthereumTransaction>]()
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
                let transactions = try results.map { try $0.unwrap() }
                let address = transactions.first?.from ?? ""
                let totalEtherAmount = transactions.reduce(0) { $0 + $1.amount }
                let depositRows = transactions.map {
                    CoinTrackingRow(
                        type: .incoming(.deposit),
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
                        let totalTokenAmount = transactions.reduce(0) { $0 + $1.amount }

                        let tradeRow = transactions.first.map { transaction in
                            [CoinTrackingRow(
                                type: .trade,
                                buyAmount: totalTokenAmount,
                                buyCurrency: transaction.token.symbol,
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
                                type: .outgoing(.withdrawal),
                                buyAmount: 0,
                                buyCurrency: "",
                                sellAmount: transaction.amount,
                                sellCurrency: transaction.token.symbol,
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
        handler: @escaping (Result<[EthereumTokenTransaction]>) -> Void
    ) {
        etherscanGateway.fetchTokenTransactions(address: address) { result in
            do {
                let transactions = try result.unwrap()
                    .filter { $0.token.symbol.uppercased() == ico.tokenSymbol.uppercased() }
                    .filter { $0.to.lowercased() == address.lowercased() }
                    .sorted(by: <)

                let firstWithdrawal = transactions.first
                let allWithdrawals = transactions
                    .filter { $0.from.lowercased() == firstWithdrawal?.from.lowercased() }

                handler(.success(allWithdrawals))
            } catch {
                handler(.failure(error))
            }
        }
    }
}
