import Algorand
import Foundation

extension AlgorandTransaction {

    init(transaction: AlgoExplorer.TransactionsResponse.Transaction) {
        let amount = Decimal(transaction.payment.amount) / Algorand.microAlgoInAlgo
        let fee = Decimal(transaction.fee) / Algorand.microAlgoInAlgo
        let senderRewards = Decimal(transaction.fromrewards) / Algorand.microAlgoInAlgo
        let receiverRewards = Decimal(transaction.payment.torewards) / Algorand.microAlgoInAlgo

        var close: AlgorandTransaction.Close?
        if
            let receiver = transaction.payment.close,
            let amount = transaction.payment.closeamount.map({ Decimal($0) / Algorand.microAlgoInAlgo }),
            let rewards = transaction.payment.closerewards.map({ Decimal($0) / Algorand.microAlgoInAlgo }) {
            close = .init(remainderReceiver: receiver, amount: amount, rewards: rewards)
        }

        self.init(
            id: transaction.tx,
            timestamp: Date(timeIntervalSince1970: Double(transaction.timestamp)),
            sender: transaction.from,
            receiver: transaction.payment.to,
            amount: amount,
            fee: fee,
            senderRewards: senderRewards,
            receiverRewards: receiverRewards,
            close: close
        )
    }
}
