import Combine
import Foundation

public protocol HashgraphGateway {

    func fetchHashgraphTransactions(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[HashgraphTransaction], Error>
}
