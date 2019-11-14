import Foundation
import TezosKit

extension TezosTransactionOperation {
    init(operation: TzStats.Operation) throws {
        guard let receiver = operation.receiver else {
            throw "Operation \(operation) has no receiver"
        }

        self.init(
            hash: operation.hash,
            sender: operation.sender,
            receiver: receiver,
            amount: operation.volume,
            fee: operation.fee,
            burn: operation.burned,
            timestamp: try operation.timestamp(),
            isSuccessful: operation.is_success
        )
    }
}
