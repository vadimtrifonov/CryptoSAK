public struct PolkadotExtrinsicsStatement {
    public let feeIncuringExtrinsics: [PolkadotExtrinsic]

    public init(extrinsics: [PolkadotExtrinsic]) {
        self.feeIncuringExtrinsics = extrinsics.filter { $0.isSuccessful && !$0.fee.isZero }
    }
}
