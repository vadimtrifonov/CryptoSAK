import Foundation

public struct EthereumStatement {
    public let incomingNormalTransactions: [EthereumTransaction]
    public let incomingInternalTransactions: [EthereumTransaction]
    public let successfulOutgoingNormalTransactions: [EthereumTransaction]
    public let successfulOutgoingInternalTransactions: [EthereumTransaction]
    public let feeIncurringTransactions: [EthereumTransaction]

    public var incomingTransactions: [EthereumTransaction] {
        (incomingNormalTransactions + incomingInternalTransactions).sorted(by: >)
    }

    public var successfulOutgoingTransactions: [EthereumTransaction] {
        (successfulOutgoingNormalTransactions + successfulOutgoingInternalTransactions).sorted(by: >)
    }

    public var balance: EthereumBalance {
        EthereumBalance(
            incomingTransactions: incomingTransactions,
            outgoingTransactions: successfulOutgoingTransactions,
            feeIncuringTransactions: feeIncurringTransactions
        )
    }

    public init(
        normalTransactions: [EthereumTransaction],
        internalTransactions: [EthereumTransaction],
        address: String
    ) {
        // Ethereum transaction with the same hash can be both outgoing and incoming
        // (address -> contract -> address, address -> address).
        // Such transaction is returned twice in the list: (1) as incoming and (2) as outgoing.
        // To correctly calcuate the balance such transactions should be deduplicated
        // Deduplication uses Set which relies on the `Hashable` implementation,
        // which should be implemented to take into account only the transaction hash.
        let incomingNormal = Set(normalTransactions.filter { $0.isIncoming(address: address) })
        let incomingInternal = Set(internalTransactions.filter { $0.isIncoming(address: address) })

        let outgoingNormal = Set(normalTransactions.filter { $0.isOutgoing(address: address) })
        let outgoingInternal = Set(internalTransactions.filter { $0.isOutgoing(address: address) })
        let outgoing = outgoingNormal.union(outgoingInternal)

        let successfulOutgoingNormal = outgoingNormal.filter(\.isSuccessful)
        let successfulOutgoingInternal = outgoingInternal.filter(\.isSuccessful)

        incomingNormalTransactions = incomingNormal.filter({ !$0.amount.isZero }).sorted(by: >)
        incomingInternalTransactions = incomingInternal.filter({ !$0.amount.isZero }).sorted(by: >)
        // Only successful transactions are debited
        successfulOutgoingNormalTransactions = successfulOutgoingNormal.filter({ !$0.amount.isZero }).sorted(by: >)
        successfulOutgoingInternalTransactions = successfulOutgoingInternal.filter({ !$0.amount.isZero }).sorted(by: >)
        // Any outgoing transaction incures fees even if it fails
        feeIncurringTransactions = outgoing.sorted(by: >)
    }
}
