import Foundation
import TezosKit

extension TezosTransactionOperation {
    init(operation: TzScanTransactionOperation) throws {
        guard let transactionOperation = operation.type.operations.first else {
            throw "No account operation in block \(operation.block_hash)"
        }

        let timestamp = try operation.timestamp()
        let amount = try transactionOperation.amount.toDecimal() / Tezos.mutezInTez
        let fee = try transactionOperation.fee.toDecimal() / Tezos.mutezInTez

        self.init(
            hash: operation.hash,
            source: Source(account: transactionOperation.src.tz, alias: transactionOperation.src.alias),
            destination: Destination(account: transactionOperation.destination.tz),
            amount: amount,
            fee: fee,
            timestamp: timestamp,
            isSuccessful: !transactionOperation.failed
        )
    }
}
