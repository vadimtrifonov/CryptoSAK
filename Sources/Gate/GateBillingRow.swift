import Foundation
import FoundationExtensions

public struct GateBillingRow {

    public enum ActionType: String, Hashable {
        case withdraw = "Withdrawals"
        case deposit = "Deposits"
        case tradingFee = "Trading Fees"
        case orderFulfilled = "Order Filled"
        case orderCancelled = "Order Cancelled"
        case orderPlaced = "Order Placed"
        case airdropBonus = "Airdrop bonus"
    }
    
    public let date: Date
    public let type: ActionType
    public let currency: String
    public let orderID: String
    public let amount: Decimal
}

extension GateBillingRow: Decodable {

    enum CodingKeys: Int, CodingKey {
        case number
        case accountType
        case date
        case type
        case currency
        case orderID
        case amount
        case availableAmount
        case additionalInfo
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "SGT") // GMT+8
        return formatter
    }()

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        date = try Self.dateFormatter.date(from: values.decode(String.self, forKey: .date))
        type = try values.decode(ActionType.self, forKey: .type)
        currency = try values.decode(String.self, forKey: .currency)
        orderID = try values.decode(String.self, forKey: .orderID)

        let rawAmount = try values.decode(String.self, forKey: .amount)
        amount = abs(try Decimal(string: rawAmount))
    }
}

extension GateBillingRow.ActionType: Decodable {}
