import Foundation

public struct GateTrade {
    public internal(set) var date: Date
    public internal(set) var buyAmount: Decimal
    public internal(set) var buyCurrency: String
    public internal(set) var sellAmount: Decimal
    public internal(set) var sellCurrency: String
    public internal(set) var fee: Decimal
    public internal(set) var feeCurrency: String
}
