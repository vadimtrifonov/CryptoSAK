import Combine
import Foundation

public protocol TezosGateway {
    func fetchTransactionOperations(account: String, startDate: Date) -> AnyPublisher<[TezosTransactionOperation], Error>
    func fetchDelegationOperations(account: String, startDate: Date) -> AnyPublisher<[TezosDelegationOperation], Error>
}
