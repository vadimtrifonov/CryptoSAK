import Foundation

public struct TezosBalance {
    public let balance: Decimal
    public let accountActivation: Decimal
    public let delegationRewards: Decimal
    public let otherIncoming: Decimal
    public let totalIncoming: Decimal
    public let outgoing: Decimal
    public let fees: Decimal
    public let burns: Decimal

    public init(
        delegationRewards: [TezosTransactionOperation],
        otherIncomingTransactions: [TezosTransactionOperation],
        outgoingTransactions: [TezosTransactionOperation],
        feeIncuringOperations: [TezosOperation],
        accountActivation: TezosOperation?
    ) {
        let accountActivation = accountActivation?.amount ?? 0

        let totalIncoming = (delegationRewards + otherIncomingTransactions).reduce(0, { $0 + $1.amount })
        let outgoing = outgoingTransactions.reduce(0, { $0 + $1.amount })
        let fees = feeIncuringOperations.reduce(0, { $0 + $1.fee })
        let burns = feeIncuringOperations.reduce(0, { $0 + $1.burn })

        self.balance = totalIncoming + accountActivation - outgoing - fees - burns
        self.accountActivation = accountActivation
        self.delegationRewards = delegationRewards.reduce(0, { $0 + $1.amount })
        self.otherIncoming = otherIncomingTransactions.reduce(0, { $0 + $1.amount })
        self.totalIncoming = totalIncoming
        self.outgoing = outgoing
        self.fees = fees
        self.burns = burns
    }
}
