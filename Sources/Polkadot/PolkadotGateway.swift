import Combine
import Foundation

public protocol PolkadotGateway {

    func fetchExtrinsics(address: String, startDate: Date) -> AnyPublisher<[PolkadotExtrinsic], Error>
}

public struct PolkadotExtrinsic {
    
    public init() {}
}

public struct PolkadotExtrinsicsStatement {

    public init(extrinsics _: [PolkadotExtrinsic]) {}
}
