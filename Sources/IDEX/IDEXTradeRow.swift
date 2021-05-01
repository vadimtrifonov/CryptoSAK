import Foundation
import FoundationExtensions

public struct IDEXTrade {

    public enum TradeType: String {
        case sell
        case buy
    }

    public enum MakerOrTaker: String {
        case maker
        case taker
    }

    public struct Market {
        public let baseCurrency: String
        public let quoteCurrency: String
    }

    public let transactionId: String
    public let transactionHash: String
    @CustomCoded<RFC3339LocalTime> public var date: Date
    public let market: Market
    public let makerOrTaker: MakerOrTaker
    public let tradeType: TradeType
    public var tokenAmount: Decimal
    public var etherAmount: Decimal
    private var usdAmount: Decimal
    public var fee: Decimal
    @CustomCoded<OptionalType<Decimal>> public var gasFee: Decimal?
    public let feeCurrency: String
}

extension IDEXTrade: Decodable {

    enum CodingKeys: Int, CodingKey {
        case transactionId
        case transactionHash
        case date
        case market
        case makerOrTaker
        case tradeType
        case tokenAmount
        case etherAmount
        case usdAmount
        case fee
        case gasFee
        case feeCurrency
    }
}

extension IDEX.IDEXTrade.Market: Decodable {

    private static let delistedCurrencies = [
        "0xf244176246168f24e3187f7288edbca29267739b": "HAV",
    ]

    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        let components = rawValue.split(separator: "/").map(String.init)

        guard var baseCurrency = components[safe: 0], var quoteCurrency = components[safe: 1] else {
            throw "Invalid currency pair \(rawValue)"
        }

        baseCurrency = Self.delistedCurrencies[baseCurrency] ?? baseCurrency
        quoteCurrency = Self.delistedCurrencies[quoteCurrency] ?? quoteCurrency

        self.init(baseCurrency: baseCurrency, quoteCurrency: quoteCurrency)
    }
}

extension IDEXTrade.MakerOrTaker: Decodable {}
extension IDEXTrade.TradeType: Decodable {}
