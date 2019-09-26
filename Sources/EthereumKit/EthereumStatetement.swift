import Foundation
import FoundationExtensions

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
    ) throws {
        // Uniqueness relies on the `Hashable` implementation which takes into account only the transaction hash
        // Ethereum transaction with the same hash can be both outgoing and incoming
        // (address -> contract -> address, address -> address)
        // NOTE: no duplicates were founds when I last tried, uniqueness check might be unfounded
        let incomingNormal = Set(normalTransactions.filter { $0.isIncoming(address: address) })
        let incomingInternal = Set(internalTransactions.filter { $0.isIncoming(address: address) })

        guard incomingNormal.intersection(incomingInternal).isEmpty else {
            throw "Unexpected hash collision between incoming normal and internal transactions"
        }

        let outgoingNormal = Set(normalTransactions.filter { $0.isOutgoing(address: address) })
        let outgoingInternal = Set(internalTransactions.filter { $0.isOutgoing(address: address) })
        let outgoing = outgoingNormal.union(outgoingInternal)

        guard outgoingNormal.intersection(outgoingInternal).isEmpty else {
            throw "Unexpected hash collision between outgoing normal and internal transactions"
        }

        let successfulOutgoingNormal = outgoingNormal.filter { $0.isSuccessful }
        let successfulOutgoingInternal = outgoingInternal.filter { $0.isSuccessful }

        incomingNormalTransactions = incomingNormal.sorted(by: >)
        incomingInternalTransactions = incomingInternal.sorted(by: >)
        // Only successful transactions are debited
        successfulOutgoingNormalTransactions = successfulOutgoingNormal.sorted(by: >)
        successfulOutgoingInternalTransactions = successfulOutgoingInternal.sorted(by: >)
        // Any outgoing transaction incures fees even if it fails
        feeIncurringTransactions = outgoing.sorted(by: >)
    }
}
