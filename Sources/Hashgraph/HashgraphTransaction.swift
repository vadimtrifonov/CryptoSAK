import Foundation

public struct HashgraphTransaction {
    public let transactionID: String
    public let readableTransactionID: String
    public let consensusTime: Date
    public let senderID: String
    public let receiverID: String
    public let amount: Decimal
    public let fee: Decimal
    public let status: Status
    public let memo: Memo

    public init(
        transactionID: String,
        readableTransactionID: String,
        consensusTime: Date,
        senderID: String,
        receiverID: String,
        amount: Decimal,
        fee: Decimal,
        status: Status,
        memo: Memo
    ) {
        self.transactionID = transactionID
        self.readableTransactionID = readableTransactionID
        self.consensusTime = consensusTime
        self.senderID = senderID
        self.receiverID = receiverID
        self.amount = amount
        self.fee = fee
        self.status = status
        self.memo = memo
    }

    public func isIncoming(account: String) -> Bool {
        receiverID.lowercased() == account.lowercased()
    }

    public func isOutgoing(account: String) -> Bool {
        senderID.lowercased() == account.lowercased()
    }
}

extension HashgraphTransaction {

    public enum Status {
        case success
    }

    public enum Memo: Equatable {
        case accountRecord
        case updateAccount
        case getAccountInfo
        case other(String)

        public var isAccountService: Bool {
            self == .accountRecord || self == .updateAccount || self == .getAccountInfo
        }

        public var rawValue: String {
            switch self {
            case .accountRecord:
                return "For account record"
            case .updateAccount:
                return "For upade account"
            case .getAccountInfo:
                return "For get account info"
            case let .other(rawValue):
                return rawValue
            }
        }
    }
}
