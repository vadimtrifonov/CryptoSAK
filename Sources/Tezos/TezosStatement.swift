import Foundation

public struct TezosStatement {

    public struct TransactionsStatement {
        public let delegationRewards: [TezosTransactionOperation]
        public let otherIncoming: [TezosTransactionOperation]
        public let outgoing: [TezosTransactionOperation]

        public var all: [TezosTransactionOperation] {
            (delegationRewards + otherIncoming + outgoing).sorted(by: >)
        }
    }

    public let transactions: TransactionsStatement
    public let successfulDelegations: [TezosDelegationOperation]
    public let feeIncuringOperations: [TezosOperation]
    public let accountActivation: TezosOperation?

    public var balance: TezosBalance {
        TezosBalance(
            delegationRewards: transactions.delegationRewards,
            otherIncomingTransactions: transactions.otherIncoming,
            outgoingTransactions: transactions.outgoing,
            feeIncuringOperations: feeIncuringOperations,
            accountActivation: accountActivation
        )
    }

    public init(
        operations: TezosOperationGroup,
        account: String,
        delegateAccounts: [String]
    ) {
        let incoming = Self.toIncoming(
            operations: operations,
            account: account,
            delegateAccounts: delegateAccounts
        )

        self.transactions = .init(
            delegationRewards: incoming.delegationRewards,
            otherIncoming: incoming.otherIncoming,
            outgoing: Self.toOutgoing(operations: operations, account: account)
        )

        self.successfulDelegations = operations.delegations.filter({ $0.isSuccessful }).sorted(by: >)
        self.feeIncuringOperations = Self.toFeeIncurring(operations: operations, account: account)
        self.accountActivation = operations.other.first(where: { $0.operationType == .accountActivation })
    }

    private static func toIncoming(
        operations: TezosOperationGroup,
        account: String,
        delegateAccounts: [String]
    ) -> (delegationRewards: [TezosTransactionOperation], otherIncoming: [TezosTransactionOperation]) {
        let incoming = operations.transactions
            .filter({ $0.isIncoming(account: account) })
            .filter({ $0.isSuccessful })
            .filter({ !$0.amount.isZero })

        let delegationRewards = incoming.filter({ delegateAccounts.containsCaseInsensetive($0.sender) })
        let otherIncoming = Set(incoming).subtracting(Set(delegationRewards))

        return (
            delegationRewards: delegationRewards.sorted(by: >),
            otherIncoming: otherIncoming.sorted(by: >)
        )
    }

    private static func toOutgoing(
        operations: TezosOperationGroup,
        account: String
    ) -> [TezosTransactionOperation] {
        operations.transactions
            .filter({ $0.isOutgoing(account: account) })
            .filter({ $0.isSuccessful })
            .filter({ !$0.amount.isZero })
    }

    private static func toFeeIncurring(
        operations: TezosOperationGroup,
        account: String
    ) -> [TezosOperation] {
        let outgoing = operations.transactions
            .filter({ $0.isOutgoing(account: account) })
            .filter({ !$0.fee.isZero || !$0.burn.isZero })

        /// Other known operations are `reveal` and `origination`, they produce only fees
        let other = operations.other
            .filter({ $0.isOutgoing(account: account) })
            .filter({ $0.operationType != .accountActivation })
            .filter({ !$0.fee.isZero || !$0.burn.isZero })

        let delegations = operations.delegations.filter({ !$0.fee.isZero || !$0.burn.isZero })

        return (outgoing.map(\.operation) + delegations.map(\.operation) + other).sorted(by: >)
    }
}

private extension Array where Element == String {

    func containsCaseInsensetive(_ element: String) -> Bool {
        contains(where: { $0.lowercased() == element.lowercased() })
    }
}
