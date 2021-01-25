public struct PolkadotExtrinsicsStatement {
    public let feeIncuringExtrinsics: [PolkadotExtrinsic]
    public let claimExtrinsic: PolkadotExtrinsic?

    public init(extrinsics: [PolkadotExtrinsic]) {
        self.feeIncuringExtrinsics = extrinsics.filter { $0.isSuccessful && !$0.fee.isZero }
        self.claimExtrinsic = extrinsics.first { extrinsic in
            extrinsic.callModule.lowercased() == "claims" &&
                extrinsic.callFunction.lowercased() == "attest"
        }
    }
}
