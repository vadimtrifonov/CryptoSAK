import Combine
import Foundation
import FoundationExtensions

public protocol EthereumGateway {
    func fetchNormalTransactions(address: String, handler: @escaping (Result<[EthereumTransaction]>) -> Void)
    func fetchInternalTransactions(address: String, handler: @escaping (Result<[EthereumTransaction]>) -> Void)
    func fetchTokenTransactions(address: String, handler: @escaping (Result<[EthereumTokenTransaction]>) -> Void)
    func fetchTransaction(hash: String, handler: @escaping (Result<EthereumTransaction>) -> Void)

    func fetchNormalTransactionsPublisher(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error>
    func fetchInternalTransactionsPublisher(address: String, startDate: Date) -> AnyPublisher<[EthereumTransaction], Error>
    func fetchTokenTransactionsPublisher(address: String, startDate: Date) -> AnyPublisher<[EthereumTokenTransaction], Error>
}
