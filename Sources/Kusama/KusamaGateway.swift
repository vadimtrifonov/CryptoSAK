import Combine
import Foundation

public protocol KusamaGateway {

    func fetchExtrinsics(
        address: String,
        startBlock: UInt,
        startDate: Date
    ) -> AnyPublisher<[KusamaExtrinsic], Error>
}
