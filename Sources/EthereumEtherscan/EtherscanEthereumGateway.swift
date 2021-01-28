import Combine
import Ethereum
import Foundation
import FoundationExtensions
import Networking

public struct EtherscanEthereumGateway: EthereumGateway {
    private let baseURL: URL = "https://api.etherscan.io"
    private let apiKey: String
    private let urlSession: URLSession

    public init(
        apiKey: String,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    public func fetchNormalTransactions(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error> {
        do {
            let endpoint = try Endpoint<Etherscan.TransactionsResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "account",
                    "action": "txlist",
                    "address": address,
                    "startblock": "0",
                    "endblock": "99999999",
                    "sort": "desc",
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    try response.result
                        .map(EthereumTransaction.init)
                        .filter { $0.date >= startDate }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func fetchInternalTransactions(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error> {
        do {
            let endpoint = try Endpoint<Etherscan.TransactionsResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "account",
                    "action": "txlistinternal",
                    "address": address,
                    "startblock": "0",
                    "endblock": "99999999",
                    "sort": "desc",
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    try response.result
                        .map(EthereumTransaction.init)
                        .filter { $0.date >= startDate }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func fetchTokenTransactions(
        address: String,
        startDate: Date
    ) -> AnyPublisher<[EthereumTokenTransaction], Error> {
        do {
            let endpoint = try Endpoint<Etherscan.TokenTransactionsResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "account",
                    "action": "tokentx",
                    "address": address,
                    "startblock": "0",
                    "endblock": "99999999",
                    "sort": "desc",
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    try response.result
                        .map(EthereumTokenTransaction.init)
                        .filter { $0.date >= startDate }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
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

    private func fetchEtherscanInternalTransaction(
        hash: String
    ) -> AnyPublisher<Etherscan.InternalTransaction, Error> {
        do {
            let endpoint = try Endpoint<Etherscan.InternalTransactionByHashResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "account",
                    "action": "txlistinternal",
                    "txhash": hash,
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    guard let transaction = response.result.first else {
                        throw "No internal transaction with hash: \(hash)"
                    }
                    return transaction
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func fetchEthereumProxyTransaction(
        hash: String
    ) -> AnyPublisher<EthereumProxy.Transaction, Error> {
        do {
            let endpoint = try Endpoint<EthereumProxy.TransactionResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "proxy",
                    "action": "eth_getTransactionByHash",
                    "txhash": hash,
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .map(\.result)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func fetchEthereumProxyBlock(
        number: String
    ) -> AnyPublisher<EthereumProxy.Block, Error> {
        do {
            let endpoint = try Endpoint<EthereumProxy.BlockResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "proxy",
                    "action": "eth_getBlockByNumber",
                    "boolean": "false",
                    "tag": number,
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .map(\.result)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func fetchEthereumProxyTransactionReceipt(
        hash: String
    ) -> AnyPublisher<EthereumProxy.TransactionReceipt, Error> {
        do {
            let endpoint = try Endpoint<EthereumProxy.TransactionReceiptResponse>(
                .get,
                url: baseURL.appendingPathComponent("/api"),
                queryItems: [
                    "module": "proxy",
                    "action": "eth_getTransactionReceipt",
                    "txhash": hash,
                    "apiKey": apiKey,
                ]
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .map(\.result)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
