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
        ) { (result: Result<EtherscanResponse<EtherscanTransaction>>) in
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
        ) { (result: Result<EtherscanResponse<EtherscanTransaction>>) in
            handler(result.flatMap({ try $0.result.map(Transaction.init) }))
        }
    }
}

private struct EtherscanResponse<T: Decodable>: Decodable {
    let status: String
    let message: String
    let result: [T]
}

private struct EtherscanTransaction: Decodable {
    let hash: String
    let timeStamp: String
    let from: String
    let to: String
    let gasPrice: String
    let gasUsed: String
}

private extension Transaction {
    
    private static let weiInEther = Decimal(pow(10,18))
    
    init(transaction: EtherscanTransaction) throws {
        let timeIntreval = try Double.make(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        let gasPriceInWei = try Decimal.make(string: transaction.gasPrice)
        let gasPriceInEther = gasPriceInWei / Transaction.weiInEther
        let gasUsed = try Decimal.make(string: transaction.gasUsed)
        let fee = gasPriceInEther * gasUsed
        
        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            fee: fee
        )
    }
}
