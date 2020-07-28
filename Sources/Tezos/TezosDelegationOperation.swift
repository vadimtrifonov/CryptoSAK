import Foundation

@dynamicMemberLookup
public struct TezosDelegationOperation {
    public let operation: TezosOperation
    public let delegate: String

    public subscript<Value>(dynamicMember keyPath: KeyPath<TezosOperation, Value>) -> Value {
        operation[keyPath: keyPath]
    }

    public init(
        operation: TezosOperation,
        delegate: String
    ) {
        self.operation = operation
        self.delegate = delegate
    }
}

extension TezosDelegationOperation: Equatable {
    public static func == (lhs: TezosDelegationOperation, rhs: TezosDelegationOperation) -> Bool {
        lhs.operation == rhs.operation
    }
}

extension TezosDelegationOperation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
    }
}

extension TezosDelegationOperation: Comparable {
    public static func < (lhs: TezosDelegationOperation, rhs: TezosDelegationOperation) -> Bool {
        lhs.operation < rhs.operation
    }
}
