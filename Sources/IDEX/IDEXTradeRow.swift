import Foundation
import FoundationExtensions

public struct IDEXTradeRow {

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
    public let date: Date
    public let market: Market
    public let makerOrTaker: MakerOrTaker
    public let tradeType: TradeType
    public let tokenAmount: Decimal
    public let etherAmount: Decimal
    public let fee: Decimal
    public let gasFee: Decimal?
    public let feeCurrency: String
}

extension IDEXTradeRow {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 12
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns)"
        }

        self.init(
            transactionId: columns[0],
            transactionHash: columns[1],
            date: try Self.dateFormatter.date(from: columns[2]),
            market: try Market(string: columns[3]),
            makerOrTaker: try MakerOrTaker(string: columns[4]),
            tradeType: try TradeType(string: columns[5]),
            tokenAmount: try Decimal(string: columns[6]),
            etherAmount: try Decimal(string: columns[7]),
            fee: try Decimal(string: columns[9]),
            gasFee: Decimal(string: columns[10]),
            feeCurrency: columns[11]
        )
    }
}

private extension IDEXTradeRow.Market {

    static let delistedCurrencies = [
        "0xf244176246168f24e3187f7288edbca29267739b": "HAV",
    ]

    init(string: String) throws {
        let components = string.split(separator: "/").map(String.init)

        guard var baseCurrency = components[safe: 0], var quoteCurrency = components[safe: 1] else {
            throw "Invalid currency pair \(string)"
        }

        baseCurrency = IDEXTradeRow.Market.delistedCurrencies[baseCurrency] ?? baseCurrency
        quoteCurrency = IDEXTradeRow.Market.delistedCurrencies[quoteCurrency] ?? quoteCurrency

        self.init(baseCurrency: baseCurrency, quoteCurrency: quoteCurrency)
    }
}
