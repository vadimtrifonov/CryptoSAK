import Foundation

public struct PolkadotExtrinsic {
    public let extrinsicID: String
    public let extrinsicHash: String
    public let block: UInt
    public let timestamp: Date
    public let callModule: String
    public let callFunction: String
    public let from: String
    public let isSuccessful: Bool
    public let fee: Decimal

    public init(
        extrinsicID: String,
        extrinsicHash: String,
        block: UInt,
        timestamp: Date,
        callModule: String,
        callFunction: String,
        from: String,
        isSuccessful: Bool,
        fee: Decimal
    ) {
        self.extrinsicID = extrinsicID
        self.extrinsicHash = extrinsicHash
        self.block = block
        self.timestamp = timestamp
        self.callModule = callModule
        self.callFunction = callFunction
        self.from = from
        self.isSuccessful = isSuccessful
        self.fee = fee
    }
}
