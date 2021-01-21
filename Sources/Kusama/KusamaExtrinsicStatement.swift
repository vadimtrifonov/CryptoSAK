public struct KusamaExtrinsicsStatement {
    public let feeIncuringExtrinsics: [KusamaExtrinsic]
    public let claimExtrinsic: KusamaExtrinsic?

    public init(extrinsics: [KusamaExtrinsic]) {
        self.feeIncuringExtrinsics = extrinsics.filter { $0.isSuccessful && !$0.fee.isZero }
        self.claimExtrinsic = extrinsics.first { extrinsic in
            extrinsic.callModule.lowercased() == "claims" &&
            extrinsic.callFunction.lowercased() == "attest"
        }
    }
}
