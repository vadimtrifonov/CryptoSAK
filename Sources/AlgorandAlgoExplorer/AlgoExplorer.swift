import Foundation

/// incoming: to, torewards
/// outgoing: from, fromrewards
/// incoming close remainder: close, closeamount, closerewards
enum AlgoExplorer {

    struct TransactionsResponse: Decodable {
        let transactions: [Transaction]

        struct Transaction: Decodable {
            let type: String
            let tx: String
            let from: String
            let fee: Int64
            let fromrewards: Int64
            let timestamp: Int64
            let payment: Payment

            struct Payment: Decodable {
                let to: String
                let amount: Int64
                let torewards: Int64
                let close: String?
                let closeamount: Int64?
                let closerewards: Int64?
            }
        }
    }
}
