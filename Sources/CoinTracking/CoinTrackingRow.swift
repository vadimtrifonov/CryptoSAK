import Foundation

public struct CoinTrackingRow: Equatable {
    public let type: TransactionType
    public let buyAmount: Decimal
    public let buyCurrency: String
    public let sellAmount: Decimal
    public let sellCurrency: String
    public let fee: Decimal
    public let feeCurrency: String
    public let exchange: String
    public let group: String
    public let comment: String
    public let date: Date
    public let transactionID: String

    public init(
        type: TransactionType,
        buyAmount: Decimal,
        buyCurrency: String,
        sellAmount: Decimal,
        sellCurrency: String,
        fee: Decimal,
        feeCurrency: String,
        exchange: String,
        group: String,
        comment: String,
        date: Date,
        transactionID: String
    ) {
        self.type = type
        self.buyAmount = buyAmount
        self.buyCurrency = buyCurrency
        self.sellAmount = sellAmount
        self.sellCurrency = sellCurrency
        self.fee = fee
        self.feeCurrency = feeCurrency
        self.exchange = exchange
        self.group = group
        self.comment = comment
        self.date = date
        self.transactionID = transactionID
    }

    public enum TransactionType: RawRepresentable, CaseIterable, Equatable {
        
        public static var allCases: [Self] {
            [trade] + [
                Incoming.allCases.map(Self.incoming),
                Outgoing.allCases.map(Self.outgoing)
            ].flatMap({ $0 })
        }
        
        case trade
        case incoming(Incoming)
        case outgoing(Outgoing)

        public var rawValue: String {
            switch self {
            case .trade:
                return Self.tradeRawValue
            case let .incoming(incoming):
                return incoming.rawValue
            case let .outgoing(outgoing):
                return outgoing.rawValue
            }
        }

        public init?(rawValue: String) {
            if rawValue == Self.tradeRawValue {
                self = .trade
            } else if let incoming = Incoming(rawValue: rawValue) {
                self = .incoming(incoming)
            } else if let outgoing = Outgoing(rawValue: rawValue) {
                self = .outgoing(outgoing)
            } else {
                return nil
            }
        }

        public enum Incoming: String, CaseIterable {
            case deposit = "Deposit"
            case income = "Income"
            case interestIncome = "Interest Income"
            case otherIncome = "Other Income"
            case rewardOrBonus = "Reward / Bonus"
            case staking = "Staking"
        }

        public enum Outgoing: String, CaseIterable {
            case otherFee = "Other Fee"
            case spend = "Spend"
            case withdrawal = "Withdrawal"
        }

        private static let tradeRawValue = "Trade"
    }
}

extension CoinTrackingRow: Comparable {
    public static func < (lhs: CoinTrackingRow, rhs: CoinTrackingRow) -> Bool {
        lhs.date < rhs.date
    }
}
