import Combine
import Foundation
import FoundationExtensions
import Hashgraph
import Networking

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

    public static func fetchHashgraphTransactions(
        urlSession: URLSession = .shared,
        accessKey: String,
        account: String,
        startDate: Date
    ) -> AnyPublisher<[HashgraphTransaction], Error> {
        do {
            let endpoint = try Endpoint<DragonGlass.TransactionsResponse>(
                .get,
                url: URL(string: "https://api.dragonglass.me/hedera/api/accounts/\(account)/transactions"),
                headers: ["X-API-KEY": accessKey],
                queryItems: ["consensusStartInEpoch": startDate.timeIntervalSince1970InMilliseconds] // not working, whatever the value all transactions are always returned
            )
            return urlSession
                .dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    try response.data
                        .map(HashgraphTransaction.init)
                        .filter({ $0.consensusTime >= startDate })
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
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

extension HashgraphTransaction {

    init(transaction: DragonGlass.TransactionsResponse.Transaction) throws {
        let memo = Memo(rawValue: transaction.memo)
        /// Hashgraph amount includes fee
        let amountWithoutFee = transaction.amount - transaction.transactionFee

        /// This detection is based on the assumption that regular transactions
        /// always transfer `amount-transactionFee` to a single receiver,
        /// with the exception of account service transactions.
        var receiverTransfer = transaction.transfers.first(where: { $0.amount == amountWithoutFee })

        if receiverTransfer == nil, memo.isAccountService {
            receiverTransfer = transaction.transfers.sorted(by: { $0.amount > $1.amount }).first
        }

        guard let receiverID = receiverTransfer?.accountID else {
            throw "Could not find Account ID of receiver of transaction ID: \(transaction.transactionID)"
        }

        let amountHBar = Decimal(amountWithoutFee) / Hashgraph.tBarInHBar
        let feeHBar = Decimal(transaction.transactionFee) / Hashgraph.tBarInHBar

        self.init(
            transactionID: transaction.transactionID,
            readableTransactionID: transaction.transactionID,
            consensusTime: try transaction.consensusTimestamp(),
            senderID: transaction.payerID,
            receiverID: receiverID,
            amount: amountHBar,
            fee: feeHBar,
            status: Status(transaction.status),
            memo: memo
        )
    }
}

extension HashgraphTransaction.Status {

    init(_ status: DragonGlass.TransactionsResponse.Transaction.Status) {
        switch status {
        case .success:
            self = .success
        }
    }
}

extension HashgraphTransaction.Memo {

    public init(rawValue: String) {
        switch rawValue {
        case "for account record":
            self = .accountRecord
        case "for update account":
            self = .updateAccount
        case "for get account info":
            self = .getAccountInfo
        default:
            self = .other(rawValue)
        }
    }
}

private extension Date {

    var timeIntervalSince1970InMilliseconds: Int {
        Int(timeIntervalSince1970) * 1000
    }
}
