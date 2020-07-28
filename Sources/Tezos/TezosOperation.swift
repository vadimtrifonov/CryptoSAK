import Foundation

public enum TezosOperationType: Hashable {
    /// This operation is used to activate accounts
    /// that were recommended allocations of tezos tokens (XTZ, “tez”)
    /// for donations to the Tezos Foundation’s fundraiser.
    case accountActivation
    case delegation
    /// This operation is used to create originated accounts.
    /// Originated accounts have addresses starting with “KT1”,
    /// unlike implicit accounts with addresses that start with “tz1”
    case origination
    /// Reveal is the first operation that need to be sent from a new address.
    /// This will reveal the public key associated to an address
    /// so that everyone can verify the signature for the operation and any future operations.
    case reveal
    case transaction
    case other(String)
}

public struct TezosOperation {
    public let operationHash: String
    public let operationType: TezosOperationType
    public let sender: String
    public let amount: Decimal
    public let fee: Decimal
    public let burn: Decimal
    public let timestamp: Date
    public let isSuccessful: Bool

    public init(
        operationHash: String,
        operationType: TezosOperationType,
        sender: String,
        amount: Decimal,
        fee: Decimal,
        burn: Decimal,
        timestamp: Date,
        isSuccessful: Bool
    ) {
        self.operationHash = operationHash
        self.operationType = operationType
        self.sender = sender
        self.amount = amount
        self.fee = fee
        self.burn = burn
        self.timestamp = timestamp
        self.isSuccessful = isSuccessful
    }

    public func isOutgoing(account: String) -> Bool {
        sender.lowercased() == account.lowercased()
    }
}

extension TezosOperation: Equatable {
    public static func == (lhs: TezosOperation, rhs: TezosOperation) -> Bool {
        lhs.operationHash == rhs.operationHash
    }
}

extension TezosOperation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(operationHash)
    }
}

extension TezosOperation: Comparable {
    public static func < (lhs: TezosOperation, rhs: TezosOperation) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
