import Combine
import Foundation
import HTTPClient
import EthereumKit
import FoundationExtensions

public class EtherscanGateway: EthereumGateway {
    let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchNormalTransactions(
        address: String,
        handler: @escaping (Result<[EthereumTransaction]>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Etherscan.TransactionsResponse>) in
            handler(result.flatMap { try $0.result.map(EthereumTransaction.init) })
        }
    }

    public func fetchInternalTransactions(
        address: String,
        handler: @escaping (Result<[EthereumTransaction]>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlistinternal",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Etherscan.TransactionsResponse>) in
            handler(result.flatMap { try $0.result.map(EthereumTransaction.init) })
        }
    }

    public func fetchTokenTransactions(
        address: String,
        handler: @escaping (Result<[EthereumTokenTransaction]>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc",
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Etherscan.TokenTransactionsResponse>) in
            handler(result.flatMap { try $0.result.map(EthereumTokenTransaction.init) })
        }
    }

    public func fetchTransaction(hash: String, handler: @escaping (Result<EthereumTransaction>) -> Void) {
        fetchEthereumTransaction(hash: hash) { [weak self] result in
            do {
                let transaction = try result.unwrap()
                self?.fetchEthereumBlock(number: transaction.blockNumber) { result in
                    do {
                        let block = try result.unwrap()
                        self?.fetchEthereumTransactionReceipt(hash: hash) { result in
                            handler(result.flatMap {
                                try EthereumTransaction(block: block, transaction: transaction, receipt: $0)
                            })
                        }
                    } catch {
                        handler(.failure(error))
                    }
                }
            } catch {
                handler(.failure(error))
            }
        }
    }

    private func fetchEthereumTransaction(
        hash: String,
        handler: @escaping (Result<EthereumProxy.Transaction>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionByHash",
            "txhash": hash,
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<EthereumProxy.TransactionResponse>) in
            handler(result.map { $0.result })
        }
    }

    private func fetchEthereumBlock(
        number: String,
        handler: @escaping (Result<EthereumProxy.Block>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getBlockByNumber",
            "boolean": "false",
            "tag": number,
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<EthereumProxy.BlockResponse>) in
            handler(result.map { $0.result })
        }
    }

    private func fetchEthereumTransactionReceipt(
        hash: String,
        handler: @escaping (Result<EthereumProxy.TransactionReceipt>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionReceipt",
            "txhash": hash,
        ]

        httpClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<EthereumProxy.TransactionReceiptResponse>) in
            handler(result.map { $0.result })
        }
    }
}

extension EtherscanGateway {
    public func fetchNormalTransactionsPublisher(address: String, startDate _: Date) -> AnyPublisher<[EthereumTransaction], Error> {
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

    public func fetchInternalTransactionsPublisher(address: String, startDate _: Date) -> AnyPublisher<[EthereumTransaction], Error> {
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

    public func fetchTokenTransactionsPublisher(address: String, startDate _: Date) -> AnyPublisher<[EthereumTokenTransaction], Error> {
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
}
