import Combine
import Foundation

public protocol PolkadotGateway {

    func fetchExtrinsics(address: String, startBlock: UInt, startDate: Date) -> AnyPublisher<[PolkadotExtrinsic], Error>
}

public struct PolkadotExtrinsic {
    public let id: String
    public let extrinsicHash: String
    public let block: UInt
    public let timestamp: Date
    public let callModule: String
    public let callFunction: String
    public let from: String
    public let isSuccessful: Bool
    public let fee: Decimal

    public init(
        id: String,
        extrinsicHash: String,
        block: UInt,
        timestamp: Date,
        callModule: String,
        callFunction: String,
        from: String,
        isSuccessful: Bool,
        fee: Decimal
    ) {
        self.id = id
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

public struct PolkadotExtrinsicsStatement {
    public let feeIncuringExtrinsics: [PolkadotExtrinsic]

    public init(extrinsics: [PolkadotExtrinsic]) {
        self.feeIncuringExtrinsics = extrinsics.filter { $0.isSuccessful && !$0.fee.isZero }
    }
}
