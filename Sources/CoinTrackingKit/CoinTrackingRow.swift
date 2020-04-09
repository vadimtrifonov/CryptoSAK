import Foundation

public struct CoinTrackingRow: Equatable {
    public let type: Type
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

    public init(
        type: Type,
        buyAmount: Decimal,
        buyCurrency: String,
        sellAmount: Decimal,
        sellCurrency: String,
        fee: Decimal,
        feeCurrency: String,
        exchange: String,
        group: String,
        comment: String,
        date: Date
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
    }

    public enum `Type`: RawRepresentable, Equatable {
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

        public enum Incoming: String {
            case deposit = "Deposit"
            case income = "Income"
            case mining = "Mining"
            case giftOrTip = "Gift/Tip"
        }

        public enum Outgoing: String {
            case withdrawal = "Withdrawal"
            case lost = "Lost"
        }

        private static let tradeRawValue = "Trade"
    }
}

extension CoinTrackingRow: Comparable {
    public static func < (lhs: CoinTrackingRow, rhs: CoinTrackingRow) -> Bool {
        lhs.date < rhs.date
    }
}
