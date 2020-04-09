import Combine
import Foundation
import HTTPClient
import LambdaKit
import TezosKit

public final class TzStatsGateway: TezosGateway {
    private let urlSession: URLSession

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func fetchTransactionOperations(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[TezosTransactionOperation], Error> {
        recursivelyFetchOperations(
            account: account,
            type: .transaction,
            accumulatedOperations: [],
            limit: 100,
            offset: 0,
            startDate: startDate
        )
        .tryMap { (operations: [TzStats.Operation]) in
            try operations.map(TezosTransactionOperation.init)
        }
        .eraseToAnyPublisher()
    }

    public func fetchDelegationOperations(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[TezosDelegationOperation], Error> {
        recursivelyFetchOperations(
            account: account,
            type: .delegation,
            accumulatedOperations: [],
            limit: 100,
            offset: 0,
            startDate: startDate
        )
        .tryMap { (operations: [TzStats.Operation]) in
            try operations.map(TezosDelegationOperation.init)
        }
        .eraseToAnyPublisher()
    }

    private func recursivelyFetchOperations(
        account: String,
        type: TzStats.OperationType,
        accumulatedOperations: [TzStats.Operation],
        limit: Int,
        offset: Int,
        startDate: Date
    ) -> AnyPublisher<[TzStats.Operation], Error> {
        fetchTransactionOperations(
            account: account,
            limit: limit,
            offset: offset
        )
        .tryMap { newOperations in
            try Self.accumulateOperations(
                type: type,
                accumulatedOperations: accumulatedOperations,
                newOperations: newOperations,
                operationsLimit: limit,
                startDate: startDate
            )
        }
        .flatMap(
            maxPublishers: .max(1)
        ) { operations, hasMoreOperations -> AnyPublisher<[TzStats.Operation], Error> in
            guard hasMoreOperations else {
                return Just(operations).mapError(toError).eraseToAnyPublisher()
            }

            return self.recursivelyFetchOperations(
                account: account,
                type: type,
                accumulatedOperations: operations,
                limit: limit,
                offset: offset + limit / 2, /// Some offset overlap is needed to compensate for the TzStats strange operations return order
                startDate: startDate
            )
        }
        .eraseToAnyPublisher()
    }

    private func fetchTransactionOperations(
        account: String,
        limit: Int,
        offset: Int
    ) -> AnyPublisher<[TzStats.Operation], Error> {
        do {
            let endpoint = try TzStats.makeAccountOperationsEndpoint(
                account: account,
                limit: limit,
                offset: offset
            )
            return urlSession.dataTaskPublisher(for: endpoint).map(\.ops).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private static func accumulateOperations(
        type: TzStats.OperationType,
        accumulatedOperations: [TzStats.Operation],
        newOperations: [TzStats.Operation],
        operationsLimit: Int,
        startDate: Date
    ) throws -> (operations: [TzStats.Operation], hasMoreOperations: Bool) {
        let filteredNewOperations = try newOperations.filter { operation in
            try operation.timestamp() >= startDate && operation.type == type.rawValue
        }

        /// TzStats returns operations in a strange order: most operations are in date order,
        /// but operations at the start and end are of different type (than those which are in the date order)
        /// and with more distant dates. Thus, operations should be deduplicated.
        let totalOperations = Array(Set(accumulatedOperations + filteredNewOperations)).sorted(by: >)
        let hasMoreOperations = newOperations.count == operationsLimit

        return (totalOperations, hasMoreOperations)
    }
}
