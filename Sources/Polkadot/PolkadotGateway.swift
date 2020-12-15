import Combine
import Foundation

public protocol PolkadotGateway {

    func fetchExtrinsics(address: String, startBlock: UInt, startDate: Date) -> AnyPublisher<[PolkadotExtrinsic], Error>
}
