import Combine
import Foundation
import TezosKit
import HTTPClient

public final class TzScanGateway: TezosGateway {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchOperations(account: String, startDate: Date) -> AnyPublisher<[TezosOperation], Error> {
        return recursivelyFetchOperations(
            account: account,
            accumulatedOperations: [],
            page: 0,
            operationsPerPage: 50,
            startDate: startDate
        )
    }

    /// https://tzscan.io/api#operation/317
    public func fetchDelegate() -> AnyPublisher<String, Error> {
        return Empty().eraseToAnyPublisher()
    }

    private func recursivelyFetchOperations(
        account: String,
        accumulatedOperations: [TezosOperation],
        page: Int,
        operationsPerPage: Int,
        startDate: Date
    ) -> AnyPublisher<[TezosOperation], Error> {
        return fetchOperations(account: account, page: page, operationsPerPage: operationsPerPage)
            .map { newOperations in
                Self.accumulateOperations(
                    accumulatedOperations: accumulatedOperations,
                    newOperations: newOperations,
                    operationsPerPage: operationsPerPage,
                    startDate: startDate
                )
            }
            .flatMap(
                maxPublishers: .max(1)
            ) { operations, hasMoreOperations -> AnyPublisher<[TezosOperation], Error> in
                guard hasMoreOperations else {
                    return Just(operations).eraseToAnyPublisherWithError()
                }

                return self.recursivelyFetchOperations(
                    account: account,
                    accumulatedOperations: operations,
                    page: page + 1,
                    operationsPerPage: operationsPerPage,
                    startDate: startDate
                )
            }
            .eraseToAnyPublisher()
    }

    /// https://tzscan.io/api#operation/323
    private func fetchOperations(
        account: String,
        page: Int,
        operationsPerPage: Int
    ) -> AnyPublisher<[TezosOperation], Error> {
        let path = "/v3/operations/" + account

        let parameters: [String: Any] = [
            "type": "Transaction",
            "p": page,
            "number": operationsPerPage,
        ]

        return httpClient.get(path: path, parameters: parameters)
            .tryMap { (operations: [TzScanOperation]) in
                print("Operations count: \(operations.count)")
                print("Last operation date: \(String(describing: operations.last?.type.operations.first?.timestamp))")

                return try operations.map(TezosOperation.init)
            }
            .eraseToAnyPublisher()
    }

    private static func accumulateOperations(
        accumulatedOperations: [TezosOperation],
        newOperations: [TezosOperation],
        operationsPerPage: Int,
        startDate: Date
    ) -> (operations: [TezosOperation], hasMoreOperations: Bool) {
        let filteredNewOperations = newOperations.filter { operation in
            operation.timestamp >= startDate
        }

        let hasMoreOperations = filteredNewOperations.count == operationsPerPage
            && filteredNewOperations.last?.timestamp != startDate

        let totalOperations = accumulatedOperations + filteredNewOperations
        return (totalOperations, hasMoreOperations)
    }
}

extension Just {
    func eraseToAnyPublisherWithError<Error>() -> AnyPublisher<Output, Error> {
        mapError { _ in NSError() as! Error }.eraseToAnyPublisher()
    }
}
