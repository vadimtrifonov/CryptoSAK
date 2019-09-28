import Combine
import EthereumKit
import Foundation
import FoundationExtensions
import HTTPClient

public class EtherscanGateway: EthereumGateway {
    let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchNormalTransactions(address: String, startDate _: Date) -> AnyPublisher<[EthereumTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .tryMap { (response: Etherscan.TransactionsResponse) in
                try response.result.map(EthereumTransaction.init)
            }
            .eraseToAnyPublisher()
    }

    public func fetchInternalTransactions(address: String, startDate _: Date) -> AnyPublisher<[EthereumTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .tryMap { (response: Etherscan.TransactionsResponse) in
                try response.result.map(EthereumTransaction.init)
            }
            .eraseToAnyPublisher()
    }

    public func fetchTokenTransactions(address: String, startDate _: Date) -> AnyPublisher<[EthereumTokenTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        return httpClient.get(
            path: "/api",
            parameters: parameters
        )
        .tryMap { (response: Etherscan.TokenTransactionsResponse) in
            try response.result.map(EthereumTokenTransaction.init)
        }
        .eraseToAnyPublisher()
    }

    public func fetchTransaction(
        hash: String
    ) -> AnyPublisher<EthereumTransaction, Error> {
        fetchEthereumProxyTransaction(hash: hash)
            .flatMap(maxPublishers: .max(1)) { transaction in
                self.fetchEthereumProxyBlock(number: transaction.blockNumber)
                    .map { ($0, transaction) }
            }
            .zip(fetchEthereumProxyTransactionReceipt(hash: hash))
            .tryMap { blockAndTransaction, receipt in
                try EthereumTransaction(
                    block: blockAndTransaction.0,
                    transaction: blockAndTransaction.1,
                    receipt: receipt
                )
            }
            .eraseToAnyPublisher()
    }

    private func fetchEthereumProxyTransaction(
        hash: String
    ) -> AnyPublisher<EthereumProxy.Transaction, Error> {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionByHash",
            "txhash": hash,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .map { (response: EthereumProxy.TransactionResponse) in
                response.result
            }
            .eraseToAnyPublisher()
    }

    private func fetchEthereumProxyBlock(
        number: String
    ) -> AnyPublisher<EthereumProxy.Block, Error> {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getBlockByNumber",
            "boolean": "false",
            "tag": number,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .map { (response: EthereumProxy.BlockResponse) in
                response.result
            }
            .eraseToAnyPublisher()
    }

    private func fetchEthereumProxyTransactionReceipt(
        hash: String
    ) -> AnyPublisher<EthereumProxy.TransactionReceipt, Error> {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionReceipt",
            "txhash": hash,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .map { (response: EthereumProxy.TransactionReceiptResponse) in
                response.result
            }
            .eraseToAnyPublisher()
    }
}
