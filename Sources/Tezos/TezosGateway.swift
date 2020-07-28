import Combine
import Foundation

public protocol TezosGateway {
    func fetchOperations(account: String, startDate: Date) -> AnyPublisher<TezosOperationGroup, Error>
}

public struct TezosOperationGroup {
    public let transactions: [TezosTransactionOperation]
    public let delegations: [TezosDelegationOperation]
    public let other: [TezosOperation]

    public init(
        transactions: [TezosTransactionOperation],
        delegations: [TezosDelegationOperation],
        other: [TezosOperation]
    ) {
        self.transactions = transactions
        self.delegations = delegations
        self.other = other
    }
}
