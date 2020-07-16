import Foundation

public struct EthereumBalance {
    public let balance: Decimal
    public let incoming: Decimal
    public let outgoing: Decimal
    public let fees: Decimal

    public init(
        incomingTransactions: [EthereumTransaction],
        outgoingTransactions: [EthereumTransaction],
        feeIncuringTransactions: [EthereumTransaction]
    ) {
        let incoming = incomingTransactions.reduce(0) { $0 + $1.amount }
        let outgoing = outgoingTransactions.reduce(0) { $0 + $1.amount }
        let fees = feeIncuringTransactions.reduce(0) { $0 + $1.fee }

        balance = incoming - outgoing - fees
        self.incoming = incoming
        self.outgoing = outgoing
        self.fees = fees
    }
}
