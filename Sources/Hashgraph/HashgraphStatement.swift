import Foundation

public struct HashgraphStatement {
    public let account: String
    public let incomingTransactions: [HashgraphTransaction]
    public let successfulOutgoingTransactions: [HashgraphTransaction]
    public let accountServiceTransactions: [HashgraphTransaction]
    /// Does not inclide account service transactions
    public let feeIncurringTransactions: [HashgraphTransaction]

    public var balance: HashgraphBalance {
        HashgraphBalance(
            incomingTransactions: incomingTransactions,
            successfulOutgoingTransactions: successfulOutgoingTransactions,
            accountServiceTransactions: accountServiceTransactions,
            feeIncurringTransactions: feeIncurringTransactions
        )
    }

    public init(account: String, transactions: [HashgraphTransaction]) {
        let outgoing = transactions.filter({ $0.isOutgoing(account: account) })

        self.account = account
        self.incomingTransactions = transactions.filter({ $0.isIncoming(account: account) })
        self.successfulOutgoingTransactions = outgoing.filter({ $0.status == .success && !$0.memo.isAccountService })
        self.accountServiceTransactions = outgoing.filter({ $0.status == .success && $0.memo.isAccountService })
        self.feeIncurringTransactions = outgoing.filter({ !$0.memo.isAccountService })
    }
}
