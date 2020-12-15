import Foundation
import FoundationExtensions

/// - Warning: CoinTracking considers transactions with the same ID as duplicates,
/// even when one is a deposit and another one is a withdrawal; therefore `Tx-ID` is not utilised.
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

    public enum TransactionType: CaseIterable, Equatable {

        public static var allCases: [Self] {
            [trade] + [
                Incoming.allCases.map(Self.incoming),
                Outgoing.allCases.map(Self.outgoing),
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

        public init(rawValue: String) throws {
            if rawValue == Self.tradeRawValue {
                self = .trade
            } else if let incoming = Incoming(rawValue: rawValue) {
                self = .incoming(incoming)
            } else if let outgoing = Outgoing(rawValue: rawValue) {
                self = .outgoing(outgoing)
            } else {
                throw "Unknown transaction type: \(rawValue), known types: \(Self.allCases.map(\.rawValue))"
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
