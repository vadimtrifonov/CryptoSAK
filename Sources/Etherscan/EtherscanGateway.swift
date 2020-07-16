import Combine
import Ethereum
import Foundation
import FoundationExtensions
import HTTPClient

public class EtherscanGateway: EthereumGateway {
    let httpClient: HTTPClient
    let apiKey: String

    public init(httpClient: HTTPClient, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    public func fetchNormalTransactions(
        address: String,
        startDate: Date
    ) -> AnyPublisher<[EthereumTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
            "apiKey": apiKey,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .tryMap { (response: Etherscan.TransactionsResponse) in
                try response.result
                    .map(EthereumTransaction.init)
                    .filter({ $0.date >= startDate })
            }
            .eraseToAnyPublisher()
    }

    public func fetchInternalTransactions(
        address: String,
        startDate: Date
    ) -> AnyPublisher<[EthereumTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
            "apiKey": apiKey,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .tryMap { (response: Etherscan.TransactionsResponse) in
                try response.result
                    .map(EthereumTransaction.init)
                    .filter({ $0.date >= startDate })
            }
            .eraseToAnyPublisher()
    }

    public func fetchTokenTransactions(
        address: String,
        startDate: Date
    ) -> AnyPublisher<[EthereumTokenTransaction], Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
            "apiKey": apiKey,
        ]

        return httpClient.get(
            path: "/api",
            parameters: parameters
        )
        .tryMap { (response: Etherscan.TokenTransactionsResponse) in
            try response.result
                .map(EthereumTokenTransaction.init)
                .filter({ $0.date >= startDate })
        }
        .eraseToAnyPublisher()
    }

    public func fetchTransaction(
        hash: String
    ) -> AnyPublisher<EthereumTransaction, Error> {
        fetchEthereumProxyTransaction(hash: hash)
            .flatMap(maxPublishers: .max(1)) { proxyTransaction in
                self.fetchEthereumProxyBlock(number: proxyTransaction.blockNumber)
                    .map { ($0, proxyTransaction) }
            }
            .zip(fetchEthereumProxyTransactionReceipt(hash: hash))
            .tryMap { proxyBlockAndTransaction, proxyReceipt in
                try EthereumTransaction(
                    proxyBlock: proxyBlockAndTransaction.0,
                    proxyTransaction: proxyBlockAndTransaction.1,
                    proxyReceipt: proxyReceipt
                )
            }
            .eraseToAnyPublisher()
    }

    public func fetchInternalTransaction(hash: String) -> AnyPublisher<EthereumInternalTransaction, Error> {
        Publishers.Zip3(
            fetchEtherscanInternalTransaction(hash: hash),
            fetchEthereumProxyTransaction(hash: hash),
            fetchEthereumProxyTransactionReceipt(hash: hash)
        )
        .tryMap { internalTransaction, proxyTransaction, proxyReceipt in
            try EthereumInternalTransaction(
                internalTransaction: internalTransaction,
                proxyTransaction: proxyTransaction,
                proxyReceipt: proxyReceipt
            )
        }
        .eraseToAnyPublisher()
    }

    private func fetchEtherscanInternalTransaction(hash: String) -> AnyPublisher<Etherscan.InternalTransaction, Error> {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "txhash": hash,
            "apiKey": apiKey,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .tryMap { (response: Etherscan.InternalTransactionByHashResponse) in
                guard let transaction = response.result.first else {
                    throw "No internal transaction with hash: \(hash)"
                }
                return transaction
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
            "apiKey": apiKey,
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
            "apiKey": apiKey,
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
            "apiKey": apiKey,
        ]

        return httpClient.get(path: "/api", parameters: parameters)
            .map { (response: EthereumProxy.TransactionReceiptResponse) in
                response.result
            }
            .eraseToAnyPublisher()
    }
}
