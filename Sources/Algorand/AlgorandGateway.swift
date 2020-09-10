import Combine
import Foundation

public protocol AlgorandGateway {
    func fetchTransactions(address: String, startDate: Date) -> AnyPublisher<[AlgorandTransaction], Error>
}
