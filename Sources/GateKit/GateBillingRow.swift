import Foundation
import FoundationExtensions

public struct GateBillingRow {

    public enum ActionType: String, Hashable {
        case withdraw = "Withdraw"
        case deposit = "Deposit"
        case traderFee = "Trade Fee"
        case orderFulfilled = "Order Fullfilled"
        case orderCancelled = "Order Cancelled"
        case orderPlaced = "Order Placed"
        case airdropBonus = "Airdrop bonus"
    }

    public let date: Date
    public let type: ActionType
    public let orderID: String
    public let amount: Decimal
    public let currency: String
}

extension GateBillingRow {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "SGT") // GMT+8
        return formatter
    }()

    private static let columns = 8

    public init(csvRow: String) throws {
        let columns = csvRow.split(separator: "\t").map(String.init)

        guard columns.count == Self.columns else {
            throw "Expected \(Self.columns) columns, got \(columns.count)"
        }

        self.init(
            date: try Self.dateFormatter.date(from: columns[2]),
            type: try ActionType(string: columns[3]),
            orderID: columns[4],
            amount: abs(try Decimal(string: columns[5])),
            currency: Self.makeCurrency(string: columns[5])
        )
    }

    private static func makeCurrency(string: String) -> String {
        return string.trimmingCharacters(in: CharacterSet.uppercaseLetters.inverted)
    }
}
