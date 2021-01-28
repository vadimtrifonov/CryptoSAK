import Combine
import Foundation
import FoundationExtensions
import Hashgraph

public enum DragonGlass {

    struct TransactionsResponse: Decodable {
        let data: [Transaction]

        struct Transaction: Decodable {
            let transactionID: String
            let payerID: String
            let consensusTime: String
            let transfers: [Transfer]
            let transactionFee: Int64
            let status: Status
            let amount: Int64
            let memo: String

            struct Transfer: Decodable {
                let accountID: String
                let amount: Int64
            }

            enum Status: String, Decodable {
                case success = "SUCCESS"
            }
        }
    }
}

extension DragonGlass.TransactionsResponse.Transaction {
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func consensusTimestamp() throws -> Date {
        try Self.dateFormatter.date(from: consensusTime)
    }
}
