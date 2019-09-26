import Foundation

public struct TezosStatement {
    public let delegationRewards: [TezosOperation]
    public let otherIncomingOperations: [TezosOperation]
    public let successfulOutgoingOperations: [TezosOperation]
    public let feeIncuringOperations: [TezosOperation]

    public var allIncomingOperations: [TezosOperation] {
        return (delegationRewards + otherIncomingOperations).sorted(by: >)
    }

    public var balance: TezosBalance {
        TezosBalance(
            delegationRewards: delegationRewards,
            otherIncomingOperations: otherIncomingOperations,
            successfulOutgoingOperations: successfulOutgoingOperations,
            feeIncuringOperations: feeIncuringOperations
        )
    }

    public init(operations: [TezosOperation], account: String, delegateAccounts: [String]) {
        let incoming = operations.filter { $0.isIncoming(account: account) }
        let outgoing = operations.filter { $0.isOutgoing(account: account) }

        let delegationRewards = incoming.filter {
            delegateAccounts.map { $0.lowercased() }.contains($0.source.account.lowercased())
        }
        let otherIncoming = Set(incoming).subtracting(Set(delegationRewards))

        let successfulOutgoing = outgoing.filter { $0.isSuccessful }
        let feeIncuringOperations = outgoing.filter { !$0.fee.isZero }

        self.delegationRewards = delegationRewards.sorted(by: >)
        otherIncomingOperations = otherIncoming.sorted(by: >)
        successfulOutgoingOperations = successfulOutgoing.sorted(by: >)
        self.feeIncuringOperations = feeIncuringOperations.sorted(by: >)
    }
}
