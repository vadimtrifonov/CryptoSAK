import Foundation
import Kusama

extension KusamaExtrinsic {

    init(response: Subscan.ExtrinsicsReponse.ResponseData.Extrinsic) throws {
        self.init(
            extrinsicID: response.extrinsic_index,
            extrinsicHash: response.extrinsic_hash,
            block: response.block_num,
            timestamp: response.timestamp,
            callModule: response.call_module.normalized(),
            callFunction: response.call_module_function.normalized(),
            from: response.account_id,
            isSuccessful: response.success,
            fee: try Decimal(string: response.fee) / Kusama.planckInKSM
        )
    }
}

private extension String {

    func normalized() -> String {
        let string = replacingOccurrences(of: "_", with: " ")
        return string.prefix(1).uppercased() + string.dropFirst().lowercased()
    }
}
