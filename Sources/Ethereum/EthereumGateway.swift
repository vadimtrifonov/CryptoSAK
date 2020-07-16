import Combine
import Foundation

public protocol EthereumGateway {
    func fetchNormalTransactions(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error>
    func fetchInternalTransactions(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error>
    func fetchTokenTransactions(address: String, startDate: Date) -> AnyPublisher<[EthereumTokenTransaction], Error>
    func fetchTransaction(hash: String) -> AnyPublisher<EthereumTransaction, Error>
    func fetchInternalTransaction(hash: String) -> AnyPublisher<EthereumInternalTransaction, Error>
}
