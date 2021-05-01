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
    @CustomCoded<RFC3339LocalTime> public var date: Date
    public var transactionID: String?

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
        transactionID: String? = nil
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
        self._date = CustomCoded(wrappedValue: date)
        self.transactionID = transactionID
    }
}

extension CoinTrackingRow {

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
            case airdrop = "Airdrop"
            case deposit = "Deposit"
            case income = "Income"
            case incomeNonTaxable = "Income (non taxable)"
            case interestIncome = "Interest Income"
            case otherIncome = "Other Income"
            case rewardOrBonus = "Reward / Bonus"
            case staking = "Staking"
        }

        public enum Outgoing: String, CaseIterable {
            case otherFee = "Other Fee"
            case spend = "Spend"
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

extension CoinTrackingRow: Codable {

    enum CodingKeys: String, CaseIterable, CodingKey {
        case type = "Type"
        case buyAmount = "Buy Amount"
        case buyCurrency = "Buy Currency"
        case sellAmount = "Sell Amount"
        case sellCurrency = "Sell Currency"
        case fee = "Fee"
        case feeCurrency = "Fee Currency"
        case exchange = "Exchange"
        case group = "Trade-Group"
        case comment = "Comment"
        case date = "Date"
    }

    public static var csvHeaders: [String] {
        CodingKeys.allCases.map(\.rawValue)
    }
}

extension CoinTrackingRow.TransactionType: Codable {

    public init(from decoder: Decoder) throws {
        try self.init(rawValue: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
