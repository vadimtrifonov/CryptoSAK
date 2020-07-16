import Foundation

public struct HashgraphBalance {
    public let balance: Decimal
    public let incoming: Decimal
    public let successfulOutgoing: Decimal
    public let accountService: Decimal
    /// Does not inclide account service fees
    public let fees: Decimal

    public init(
        incomingTransactions: [HashgraphTransaction],
        successfulOutgoingTransactions: [HashgraphTransaction],
        accountServiceTransactions: [HashgraphTransaction],
        feeIncurringTransactions: [HashgraphTransaction]
    ) {
        let incoming = incomingTransactions.reduce(0, { $0 + $1.amount })
        let successfulOutgoing = successfulOutgoingTransactions.reduce(0, { $0 + $1.amount })
        let accountService = accountServiceTransactions.reduce(0, { $0 + $1.amount + $1.fee })
        let fees = feeIncurringTransactions.reduce(0, { $0 + $1.fee })

        self.balance = incoming - successfulOutgoing - accountService - fees
        self.incoming = incoming
        self.successfulOutgoing = successfulOutgoing
        self.accountService = accountService
        self.fees = fees
    }
}
