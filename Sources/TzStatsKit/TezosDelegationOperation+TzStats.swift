import Foundation
import TezosKit

extension TezosDelegationOperation {
    init(operation: TzStats.Operation) throws {
        guard let delegate = operation.delegate else {
            throw "Operation \(operation) has no delegate"
        }

        self.init(
            hash: operation.hash,
            sender: operation.sender,
            delegate: delegate,
            fee: operation.fee,
            timestamp: try operation.timestamp(),
            isSuccessful: operation.is_success
        )
    }
}
