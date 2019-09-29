import Foundation
import TezosKit

extension TezosDelegationOperation {
    init(operation: TzScanDelegationOperation) throws {
        guard let delegationOperation = operation.type.operations.first else {
            throw "No account operation in block \(operation.block_hash)"
        }

        let timestamp = try operation.timestamp()
        let fee = try delegationOperation.fee.toDecimal() / Tezos.mutezInTez

        self.init(
            hash: operation.hash,
            source: Source(account: delegationOperation.src.tz),
            delegate: Delegate(account: delegationOperation.delegate.tz, alias: delegationOperation.delegate.alias),
            fee: fee,
            timestamp: timestamp,
            isSuccessful: !delegationOperation.failed
        )
    }
}
