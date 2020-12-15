import Foundation
import Polkadot

extension PolkadotExtrinsic {

    init(response: Subscan.ExtrinsicsReponse.ResponseData.Extrinsic) throws {
        self.init(
            extrinsicID: response.extrinsic_index,
            extrinsicHash: response.extrinsic_hash,
            block: response.block_num,
            timestamp: response.timestamp,
            callModule: response.call_module.normalized(),
            callFunction: response.call_module_function.normalized(),
            from: response.from,
            isSuccessful: response.success,
            fee: try Decimal(string: response.fee) / Polkadot.planckInDOT
        )
    }
}

private extension String {

    func normalized() -> String {
        let string = replacingOccurrences(of: "_", with: " ")
        return string.prefix(1).uppercased() + string.dropFirst().lowercased()
    }
}
