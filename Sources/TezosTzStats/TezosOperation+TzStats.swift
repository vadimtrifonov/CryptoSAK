import Foundation
import Tezos

extension TezosOperationType: RawRepresentable {

    public var rawValue: String {
        switch self {
        case .accountActivation:
            return "activate_account"
        case .delegation, .origination, .reveal, .transaction:
            return String(describing: self)
        case let .other(rawValue):
            return rawValue
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case Self.accountActivation.rawValue:
            self = .accountActivation
        case Self.delegation.rawValue:
            self = .delegation
        case Self.origination.rawValue:
            self = .origination
        case Self.reveal.rawValue:
            self = .reveal
        case Self.transaction.rawValue:
            self = .transaction
        default:
            self = .other(rawValue)
        }
    }
}

extension TezosOperation {

    init(operation: TzStats.Operation) throws {
        self.init(
            operationHash: operation.hash,
            operationType: .init(rawValue: operation.type),
            sender: operation.sender,
            amount: operation.volume.decimal,
            fee: operation.fee.decimal,
            burn: operation.burned.decimal,
            timestamp: try operation.timestamp(),
            isSuccessful: operation.is_success
        )
    }
}

extension TezosTransactionOperation {

    init(operation: TzStats.Operation) throws {
        guard let receiver = operation.receiver else {
            throw "Operation \(operation) has no receiver"
        }

        try self.init(
            operation: .init(operation: operation),
            receiver: receiver
        )
    }
}

extension TezosDelegationOperation {
    init(operation: TzStats.Operation) throws {
        guard let delegate = operation.delegate else {
            throw "Operation \(operation) has no delegate"
        }

        try self.init(
            operation: .init(operation: operation),
            delegate: delegate
        )
    }
}

extension TezosOperationGroup {

    init(operations: [TzStats.Operation]) throws {
        let transactions = try operations
            .filter({ TezosOperationType(rawValue: $0.type) == .transaction })
            .map(TezosTransactionOperation.init)

        let delegations = try operations
            .filter({ TezosOperationType(rawValue: $0.type) == .delegation })
            .map(TezosDelegationOperation.init)

        let other = try operations
            .filter({ ![.transaction, .delegation].contains(TezosOperationType(rawValue: $0.type)) })
            .map(TezosOperation.init)

        self.init(
            transactions: transactions,
            delegations: delegations,
            other: other
        )
    }
}
