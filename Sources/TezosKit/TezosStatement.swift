import Foundation

public struct TezosStatement {
    public let transactions: TransactionsStatement
    public let successfulDelegations: [TezosDelegationOperation]
    public let feeIncuringOperations: [TezosOperation]

    public var balance: TezosBalance {
        TezosBalance(
            delegationRewards: transactions.delegationRewards,
            otherIncomingTransactions: transactions.otherIncoming,
            successfulOutgoingTransactions: transactions.successfulOutgoing,
            feeIncuringOperations: feeIncuringOperations
        )
    }

    public init(
        transactions: [TezosTransactionOperation],
        delegations: [TezosDelegationOperation],
        account: String,
        delegateAccounts: [String]
    ) {
        let incoming = transactions.filter { $0.isIncoming(account: account) }
        let outgoing = transactions.filter { $0.isOutgoing(account: account) }

        let delegationRewards = incoming.filter { transaction in
            delegateAccounts.map({ $0.lowercased() }).contains(transaction.sender.lowercased())
        }
        let otherIncoming = Set(incoming).subtracting(Set(delegationRewards))

        let successfulOutgoing = outgoing.filter { $0.isSuccessful }
        let successfulDelegations = delegations.filter { $0.isSuccessful }

        let feeIncuringOutgoing: [TezosOperation] = outgoing.filter({ !$0.fee.isZero })
        let feeIncuringDelegations: [TezosOperation] = delegations.filter({ !$0.fee.isZero })
        let feeIncuringOperations = feeIncuringOutgoing + feeIncuringDelegations

        self.transactions = .init(
            delegationRewards: delegationRewards.sorted(by: >),
            otherIncoming: otherIncoming.sorted(by: >),
            successfulOutgoing: successfulOutgoing.sorted(by: >)
        )
        self.successfulDelegations = successfulDelegations.sorted(by: >)
        self.feeIncuringOperations = feeIncuringOperations.sorted(by: { $0.timestamp > $1.timestamp })
    }

    public struct TransactionsStatement {
        public let delegationRewards: [TezosTransactionOperation]
        public let otherIncoming: [TezosTransactionOperation]
        public let successfulOutgoing: [TezosTransactionOperation]

        public var all: [TezosTransactionOperation] {
            return (delegationRewards + otherIncoming + successfulOutgoing).sorted(by: >)
        }
    }
}
