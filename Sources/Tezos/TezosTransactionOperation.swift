import Foundation

@dynamicMemberLookup
public struct TezosTransactionOperation {
    public let operation: TezosOperation
    public let receiver: String

    public subscript<Value>(dynamicMember keyPath: KeyPath<TezosOperation, Value>) -> Value {
        operation[keyPath: keyPath]
    }

    public init(
        operation: TezosOperation,
        receiver: String
    ) {
        self.operation = operation
        self.receiver = receiver
    }

    public func isIncoming(account: String) -> Bool {
        receiver.lowercased() == account.lowercased()
    }

    public func isOutgoing(account: String) -> Bool {
        operation.isOutgoing(account: account)
    }
}

extension TezosTransactionOperation: Equatable {
    public static func == (lhs: TezosTransactionOperation, rhs: TezosTransactionOperation) -> Bool {
        lhs.operation == rhs.operation
    }
}

extension TezosTransactionOperation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
    }
}

extension TezosTransactionOperation: Comparable {
    public static func < (lhs: TezosTransactionOperation, rhs: TezosTransactionOperation) -> Bool {
        lhs.operation < rhs.operation
    }
}
