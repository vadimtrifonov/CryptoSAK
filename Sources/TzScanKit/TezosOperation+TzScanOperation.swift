import Foundation
import TezosKit

extension TezosOperation {
    private static let dateFormatter = ISO8601DateFormatter()

    init(operation: TzScanOperation) throws {
        guard let accountOperation = operation.type.operations.first else {
            throw "No account operation in block \(operation.block_hash)"
        }

        let timestamp = try Self.dateFormatter.makeDate(string: accountOperation.timestamp)

        let amount = try accountOperation.amount.toDecimal() / Tezos.mutezInTez
        let fee = try accountOperation.fee.toDecimal() / Tezos.mutezInTez

        self.init(
            hash: operation.hash,
            source: Source(account: accountOperation.src.tz, alias: accountOperation.src.alias),
            destination: Destination(account: accountOperation.destination.tz),
            amount: amount,
            fee: fee,
            timestamp: timestamp,
            isSuccessful: !accountOperation.failed
        )
    }
}
