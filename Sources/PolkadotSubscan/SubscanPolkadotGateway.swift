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

    public func fetchExtrinsics(
        address: String,
        startDate _: Date
    ) -> AnyPublisher<[PolkadotExtrinsic], Error> {
        do {
            let endpoint = try Endpoint<Subscan.ExtrinsicsReponse>(
                json: .post,
                url: URL(string: "https://polkadot.subscan.io/api/open/account/extrinsics"),
                body: Subscan.ExtrinsicsRequest(address: address)
            )
            return urlSession.dataTaskPublisher(for: endpoint).map { response in
                response.data.extrinsics.map(PolkadotExtrinsic.init)
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

enum Subscan {

    struct ExtrinsicsRequest: Encodable {
        let address: String
    }

    struct ExtrinsicsReponse: Decodable {
        let data: ResponseData

        struct ResponseData: Decodable {
            let extrinsics: [Extrinsic]

            struct Extrinsic: Decodable {
                let block_timestamp: UInt64
                let call_module: String
                let call_module_function: String
                let from: String
                let success: String
            }
        }
    }
}

extension PolkadotExtrinsic {
    
    init(respose: Subscan.ExtrinsicsReponse.ResponseData.Extrinsic) {
        self.init()
    }
}
