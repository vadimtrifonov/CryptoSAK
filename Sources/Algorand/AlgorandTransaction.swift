import Foundation

public struct AlgorandTransaction {

    public struct Close {
        public let remainderReceiver: String
        public let amount: Decimal
        public let rewards: Decimal

        public init(
            remainderReceiver: String,
            amount: Decimal,
            rewards: Decimal
        ) {
            self.remainderReceiver = remainderReceiver
            self.amount = amount
            self.rewards = rewards
        }
    }

    public let id: String
    public let timestamp: Date
    public let sender: String
    public let receiver: String
    public let amount: Decimal
    public let fee: Decimal
    public let senderRewards: Decimal
    public let receiverRewards: Decimal
    public let close: Close?

    public init(
        id: String,
        timestamp: Date,
        sender: String,
        receiver: String,
        amount: Decimal,
        fee: Decimal,
        senderRewards: Decimal,
        receiverRewards: Decimal,
        close: Close?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sender = sender
        self.receiver = receiver
        self.amount = amount
        self.fee = fee
        self.senderRewards = senderRewards
        self.receiverRewards = receiverRewards
        self.close = close
    }
}
