import Foundation

public struct AlgorandBalance {
    public let balance: Decimal
    public let incoming: Decimal
    public let outgoing: Decimal
    public let fee: Decimal
    public let rewards: Decimal
    public let closeRemainders: Decimal

    public init(
        incomingTransactions: [AlgorandTransaction],
        outgoingTransactions: [AlgorandTransaction],
        closeTransactions: [AlgorandTransaction]
    ) {
        let incoming = incomingTransactions.reduce(0, { $0 + $1.amount })
        let outgoing = outgoingTransactions.reduce(0, { $0 + $1.amount })
        let fee = outgoingTransactions.reduce(0, { $0 + $1.fee })
        let closeRemainders = closeTransactions.compactMap(\.close).reduce(0, { $0 + $1.amount })

        let incomingRewards = incomingTransactions.reduce(0, { $0 + $1.receiverRewards })
        let outgoingRewards = outgoingTransactions.reduce(0, { $0 + $1.senderRewards })
        let closeRewards = closeTransactions.compactMap(\.close).reduce(0, { $0 + $1.rewards })
        let rewards = incomingRewards + outgoingRewards + closeRewards

        self.balance = incoming + closeRemainders + rewards - outgoing - fee
        self.incoming = incoming
        self.outgoing = outgoing
        self.fee = fee
        self.closeRemainders = closeRemainders
        self.rewards = rewards
    }
}
