import Foundation

public class EtherscanGatewayImpl: EtherscanGateway {
    let apiClient: APIClient
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchNormalTransactions(
        address: String,
        handler: @escaping (Result<[Transaction]>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "txlist",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc"
        ]
        
        apiClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Etherscan.TransactionsResponse>) in
            handler(result.flatMap({ try $0.result.map(Transaction.init) }))
        }
    }

    public func fetchTokenTransactions(
        address: String,
        handler: @escaping (Result<[Transaction]>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": "0",
            "endblock": "99999999",
            "sort": "desc"
        ]

        apiClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Etherscan.TransactionsResponse>) in
            handler(result.flatMap({ try $0.result.map(Transaction.init) }))
        }
    }
    
    public func fetchTransaction(hash: String, handler: @escaping (Result<Transaction>) -> Void) {
        fetchEthereumTransaction(hash: hash) { [weak self] result in
            do {
                let transaction = try result.unwrap()
                self?.fetchEthereumBlock(number: transaction.blockNumber) { result in
                    do {
                        let block = try result.unwrap()
                        self?.fetchEthereumTransactionReceipt(hash: hash) { result in
                            handler(result.flatMap {
                                try Transaction(block: block, transaction: transaction, receipt: $0)
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
        handler: @escaping (Result<Ethereum.Transaction>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionByHash",
            "txhash": hash
        ]
        
        apiClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Ethereum.TransactionResponse>) in
            handler(result.map({ $0.result }))
        }
    }
    
    private func fetchEthereumBlock(
        number: String,
        handler: @escaping (Result<Ethereum.Block>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getBlockByNumber",
            "boolean": "false",
            "tag": number
        ]
        
        apiClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Ethereum.BlockResponse>) in
            handler(result.map({ $0.result }))
        }
    }
    
    private func fetchEthereumTransactionReceipt(
        hash: String,
        handler: @escaping (Result<Ethereum.TransactionReceipt>) -> Void
    ) {
        let parameters: [String: Any] = [
            "module": "proxy",
            "action": "eth_getTransactionReceipt",
            "txhash": hash
        ]
        
        apiClient.get(
            path: "/api",
            parameters: parameters
        ) { (result: Result<Ethereum.TransactionReceiptResponse>) in
            handler(result.map({ $0.result }))
        }
    }
}
