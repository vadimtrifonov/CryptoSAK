import Foundation

public struct AlgorandStatement {
    public let incomingTransactions: [AlgorandTransaction]
    public let outgoingTransactions: [AlgorandTransaction]
    public let feeIncuringTransactions: [AlgorandTransaction]
    public let closeTransactions: [AlgorandTransaction]
    public let incomingRewards: [AlgorandTransaction]
    public let outgoingRewards: [AlgorandTransaction]
    public let closeRewards: [AlgorandTransaction]

    public var balance: AlgorandBalance {
        .init(
            incomingTransactions: incomingTransactions,
            outgoingTransactions: outgoingTransactions,
            closeTransactions: closeTransactions
        )
    }

    public init(address: String, transactions: [AlgorandTransaction]) {
        let incoming = transactions.filter({ $0.receiver.lowercased() == address.lowercased() })
        let outgoing = transactions.filter({ $0.sender.lowercased() == address.lowercased() })

        let closures = transactions.filter { transaction in
            transaction.close.map { close in
                close.remainderReceiver.lowercased() == address.lowercased() && !close.amount.isZero
            } ?? false
        }

        let incomingRewards = incoming.filter({ !$0.receiverRewards.isZero })
        let outgoingRewards = outgoing.filter({ !$0.senderRewards.isZero })
        let closeRewards = closures.filter({ !$0.senderRewards.isZero })

        self.incomingTransactions = incoming
        self.outgoingTransactions = outgoing.filter { !$0.amount.isZero }
        self.feeIncuringTransactions = outgoing
        self.closeTransactions = closures
        self.incomingRewards = incomingRewards
        self.outgoingRewards = outgoingRewards
        self.closeRewards = closeRewards
    }
}
