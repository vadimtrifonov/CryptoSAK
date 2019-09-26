import Combine
import Foundation

public protocol TezosGateway {
    func fetchOperations(account: String, startDate: Date) -> AnyPublisher<[TezosOperation], Error>
}
