import Combine
import Foundation
import FoundationExtensions
import Networking
import Polkadot

public struct SubscanPolkadotGateway: PolkadotGateway {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func fetchBlockTimestamp(blockNumber: Int) -> AnyPublisher<Date, Error> {
        do {
            let endpoint = try Endpoint<Subscan.BlockResponse>(
                json: .post,
                url: URL(string: "https://polkadot.subscan.io/api/open/block"),
                body: Subscan.BlockRequest(block_num: blockNumber)
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .map(\.data.block_timestamp)
                .map(TimeInterval.init)
                .map(Date.init(timeIntervalSince1970:))
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

enum Subscan {

    struct BlockRequest: Encodable {
        let block_num: Int
    }

    struct BlockResponse: Decodable {
        let data: ResponseData

        struct ResponseData: Decodable {
            let block_timestamp: Int
        }
    }
}
