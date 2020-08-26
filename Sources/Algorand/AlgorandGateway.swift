import Combine

public protocol AlgorandGateway {
    func fetchTransactions(address: String) -> AnyPublisher<[AlgorandTransaction], Error>
}
