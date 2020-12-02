import Combine
import Foundation
import FoundationExtensions
import Lambda
import Networking
import Polkadot

public struct SubscanPolkadotGateway: PolkadotGateway {
    private let urlSession: URLSession
    private let rows: UInt = 10

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// https://polkadot.subscan.io/api/scan/extrinsics
    public func fetchExtrinsics(
        address: String,
        startBlock: UInt,
        startDate: Date
    ) -> AnyPublisher<[PolkadotExtrinsic], Error> {
        recusrsivelyFetchExtrinsics(
            address: address,
            accumulatedExtrinsics: [],
            rows: rows,
            page: 0,
            startBlock: startBlock,
            startDate: startDate
        ).tryMap { extrinsics in
            try extrinsics.map(PolkadotExtrinsic.init)
        }
        .eraseToAnyPublisher()
    }

    private func recusrsivelyFetchExtrinsics(
        address: String,
        accumulatedExtrinsics: [Subscan.ExtrinsicsReponse.ResponseData.Extrinsic],
        rows: UInt,
        page: UInt,
        startBlock: UInt,
        startDate: Date
    ) -> AnyPublisher<[Subscan.ExtrinsicsReponse.ResponseData.Extrinsic], Error> {
        fetchExtrinsics(
            address: address,
            rows: rows,
            page: page
        )
        .map { extrinsics in
            Self.accumulateExtrinsics(
                accumulatedExtrinsics: accumulatedExtrinsics,
                newExtrinsics: extrinsics,
                rows: rows,
                startBlock: startBlock,
                startDate: startDate
            )
        }
        .flatMap(
            maxPublishers: .max(1)
        ) { extrinsics, hasMore -> AnyPublisher<[Subscan.ExtrinsicsReponse.ResponseData.Extrinsic], Error> in
            guard hasMore else {
                return Just(extrinsics).mapError(toError).eraseToAnyPublisher()
            }

            return self.recusrsivelyFetchExtrinsics(
                address: address,
                accumulatedExtrinsics: extrinsics,
                rows: rows,
                page: page + 1,
                startBlock: startBlock,
                startDate: startDate
            )
        }
        .eraseToAnyPublisher()
    }

    private func fetchExtrinsics(
        address: String,
        rows: UInt,
        page: UInt
    ) -> AnyPublisher<[Subscan.ExtrinsicsReponse.ResponseData.Extrinsic], Error> {
        do {
            let endpoint = try Endpoint<Subscan.ExtrinsicsReponse>(
                json: .post,
                url: URL(string: "https://polkadot.subscan.io/api/open/account/extrinsics"),
                body: Subscan.ExtrinsicsRequest(address: address, row: rows, page: page)
            )
            return urlSession.dataTaskPublisher(for: endpoint)
                .map(\.data.extrinsics)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private static func accumulateExtrinsics(
        accumulatedExtrinsics: [Subscan.ExtrinsicsReponse.ResponseData.Extrinsic],
        newExtrinsics: [Subscan.ExtrinsicsReponse.ResponseData.Extrinsic],
        rows: UInt,
        startBlock: UInt,
        startDate: Date
    ) -> (extrinsics: [Subscan.ExtrinsicsReponse.ResponseData.Extrinsic], hasMore: Bool) {
        let filteredNewExtrinsics = newExtrinsics.filter { extrinsic in
            extrinsic.block_num >= startBlock && extrinsic.timestamp >= startDate
        }

        let totalExtrinsics = accumulatedExtrinsics + filteredNewExtrinsics
        let hasMore = newExtrinsics.count == rows

        return (extrinsics: totalExtrinsics, hasMore: hasMore)
    }
}

enum Subscan {

    struct ExtrinsicsRequest: Encodable {
        let address: String
        let row: UInt
        let page: UInt
    }

    struct ExtrinsicsReponse: Decodable {
        let data: ResponseData

        struct ResponseData: Decodable {
            let count: UInt
            let extrinsics: [Extrinsic]

            struct Extrinsic: Decodable {
                let block_num: UInt
                let block_timestamp: UInt64
                let extrinsic_index: String
                let extrinsic_hash: String
                let call_module: String
                let call_module_function: String
                let from: String
                let success: Bool
                let fee: String
            }
        }
    }
}

extension Subscan.ExtrinsicsReponse.ResponseData.Extrinsic {

    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(block_timestamp))
    }
}

extension PolkadotExtrinsic {

    init(response: Subscan.ExtrinsicsReponse.ResponseData.Extrinsic) throws {
        self.init(
            id: response.extrinsic_index,
            extrinsicHash: response.extrinsic_hash,
            block: response.block_num,
            timestamp: response.timestamp,
            callModule: response.call_module.normalized(),
            callFunction: response.call_module_function.normalized(),
            from: response.from,
            isSuccessful: response.success,
            fee: try Decimal(string: response.fee) / Polkadot.planckInDOT
        )
    }
}

private extension String {

    func normalized() -> String {
        let string = replacingOccurrences(of: "_", with: " ")
        return string.prefix(1).uppercased() + string.dropFirst().lowercased()
    }
}
