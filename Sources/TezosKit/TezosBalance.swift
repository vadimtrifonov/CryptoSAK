import Foundation

public struct TezosBalance {
    public let balance: Decimal
    public let delegationRewards: Decimal
    public let otherIncoming: Decimal
    public let totalIncoming: Decimal
    public let successfulOutgoing: Decimal
    public let fees: Decimal

    public init(
        delegationRewards: [TezosTransactionOperation],
        otherIncomingTransactions: [TezosTransactionOperation],
        successfulOutgoingTransactions: [TezosTransactionOperation],
        feeIncuringOperations: [TezosOperation]
    ) {
        let allIncomingOperations = delegationRewards + otherIncomingTransactions
        let delegationRewards = delegationRewards.reduce(0) { $0 + $1.amount }
        let otherIncoming = otherIncomingTransactions.reduce(0) { $0 + $1.amount }
        let incoming = allIncomingOperations.reduce(0) { $0 + $1.amount }

        let successfulOutgoing = successfulOutgoingTransactions.reduce(0) { $0 + $1.amount }
        let fees = feeIncuringOperations.reduce(0) { $0 + $1.fee + $1.burn }

        balance = incoming - successfulOutgoing - fees
        self.delegationRewards = delegationRewards
        self.otherIncoming = otherIncoming
        self.totalIncoming = incoming
        self.successfulOutgoing = successfulOutgoing
        self.fees = fees
    }
}
