import Foundation
import Hashgraph

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
