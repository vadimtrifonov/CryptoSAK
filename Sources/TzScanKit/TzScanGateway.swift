import Combine
import Foundation
import HTTPClient
import TezosKit

public final class TzScanGateway: TezosGateway {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchTransactionOperations(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[TezosTransactionOperation], Error> {
        return recursivelyFetchOperations(
            account: account,
            type: .transaction,
            accumulatedOperations: [],
            page: 0,
            operationsPerPage: 50,
            startDate: startDate
        )
        .tryMap { (operations: [TzScanTransactionOperation]) in
            try operations.map(TezosTransactionOperation.init)
        }
        .eraseToAnyPublisher()
    }

    public func fetchDelegationOperations(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[TezosDelegationOperation], Error> {
        return recursivelyFetchOperations(
            account: account,
            type: .delegation,
            accumulatedOperations: [],
            page: 0,
            operationsPerPage: 50,
            startDate: startDate
        )
        .tryMap { (operations: [TzScanDelegationOperation]) in
            try operations.map(TezosDelegationOperation.init)
        }
        .eraseToAnyPublisher()
    }

    private func recursivelyFetchOperations<Operation: TzScanOperation>(
        account: String,
        type: TzScanOperationType,
        accumulatedOperations: [Operation],
        page: Int,
        operationsPerPage: Int,
        startDate: Date
    ) -> AnyPublisher<[Operation], Error> {
        return fetchTransactionOperations(
            account: account,
            type: type,
            page: page,
            operationsPerPage: operationsPerPage
        )
        .tryMap { newOperations in
            try Self.accumulateOperations(
                accumulatedOperations: accumulatedOperations,
                newOperations: newOperations,
                operationsPerPage: operationsPerPage,
                startDate: startDate
            )
        }
        .flatMap(
            maxPublishers: .max(1)
        ) { operations, hasMoreOperations -> AnyPublisher<[Operation], Error> in
            guard hasMoreOperations else {
                return Just(operations).eraseToAnyPublisherWithError()
            }

            return self.recursivelyFetchOperations(
                account: account,
                type: type,
                accumulatedOperations: operations,
                page: page + 1,
                operationsPerPage: operationsPerPage,
                startDate: startDate
            )
        }
        .eraseToAnyPublisher()
    }

    /// https://tzscan.io/api#operation/323
    private func fetchTransactionOperations<Operation: TzScanOperation>(
        account: String,
        type: TzScanOperationType,
        page: Int,
        operationsPerPage: Int
    ) -> AnyPublisher<[Operation], Error> {
        let path = "/v3/operations/" + account

        let parameters: [String: Any] = [
            "type": type.rawValue,
            "p": page,
            "number": operationsPerPage,
        ]

        return httpClient.get(path: path, parameters: parameters)
    }

    private static func accumulateOperations<Operation: TzScanOperation>(
        accumulatedOperations: [Operation],
        newOperations: [Operation],
        operationsPerPage: Int,
        startDate: Date
    ) throws -> (operations: [Operation], hasMoreOperations: Bool) {
        let filteredNewOperations = try newOperations.filter { operation in
            try operation.timestamp() >= startDate
        }

        let hasMoreOperations = try filteredNewOperations.count == operationsPerPage
            && filteredNewOperations.last?.timestamp() != startDate

        let totalOperations = accumulatedOperations + filteredNewOperations
        return (totalOperations, hasMoreOperations)
    }
}

extension Just {
    func eraseToAnyPublisherWithError<Error>() -> AnyPublisher<Output, Error> {
        mapError({ _ in NSError() as! Error }).eraseToAnyPublisher()
    }
}
