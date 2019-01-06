public protocol EtherscanGateway {
    func fetchNormalTransactions(address: String, handler: @escaping (Result<[Transaction]>) -> Void)
    func fetchInternalTransactions(address: String, handler: @escaping (Result<[Transaction]>) -> Void)
    func fetchTokenTransactions(address: String, handler: @escaping (Result<[TokenTransaction]>) -> Void)
    func fetchTransaction(hash: String, handler: @escaping (Result<Transaction>) -> Void)
}
