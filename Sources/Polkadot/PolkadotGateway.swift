import Combine
import Foundation

public protocol PolkadotGateway {

    func fetchBlockTimestamp(blockNumber: Int) -> AnyPublisher<Date, Error>
}
