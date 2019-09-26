import Foundation

public struct TezosBalance {
    public let balance: Decimal
    public let delegationRewards: Decimal
    public let otherIncoming: Decimal
    public let totalIncoming: Decimal
    public let outgoing: Decimal
    public let fees: Decimal

    public init(
        delegationRewards: [TezosOperation],
        otherIncomingOperations: [TezosOperation],
        successfulOutgoingOperations: [TezosOperation],
        feeIncuringOperations: [TezosOperation]
    ) {
        let allIncomingOperations = delegationRewards + otherIncomingOperations
        let delegationRewards = delegationRewards.reduce(0) { $0 + $1.amount }
        let otherIncoming = otherIncomingOperations.reduce(0) { $0 + $1.amount }
        let incoming = allIncomingOperations.reduce(0) { $0 + $1.amount }
        let outgoing = successfulOutgoingOperations.reduce(0) { $0 + $1.amount }
        let fees = feeIncuringOperations.reduce(0) { $0 + $1.fee }

        balance = incoming - outgoing - fees
        self.delegationRewards = delegationRewards
        self.otherIncoming = otherIncoming
        totalIncoming = incoming
        self.outgoing = outgoing
        self.fees = fees
    }
}
