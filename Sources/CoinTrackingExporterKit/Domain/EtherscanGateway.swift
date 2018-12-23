public protocol EtherscanGateway {
    func fetchNormalTransactions(address: String, handler: @escaping (Result<[Transaction]>) -> Void)
    func fetchTokenTransactions(address: String, handler: @escaping (Result<[Transaction]>) -> Void)
}
