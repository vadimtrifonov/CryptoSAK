import Foundation

enum Subscan {

    struct ExtrinsicsRequest: Encodable {
        let address: String
        let row: UInt
        let page: UInt
    }

    struct ExtrinsicsReponse: Decodable {
        let data: ResponseData

        struct ResponseData: Decodable {
            let count: UInt
            let extrinsics: [Extrinsic]

            struct Extrinsic: Decodable {
                let account_id: String
                let block_num: UInt
                let block_timestamp: UInt64
                let call_module: String
                let call_module_function: String
                let extrinsic_hash: String
                let extrinsic_index: String
                let fee: String
                let success: Bool
            }
        }
    }
}

extension Subscan.ExtrinsicsReponse.ResponseData.Extrinsic {

    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(block_timestamp))
    }
}
