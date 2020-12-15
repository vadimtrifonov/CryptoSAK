import CoinTracking

extension CoinTrackingRow {

    func applyOverride(
        from transactions: [KnownTransaction],
        withTransactionID transactionID: String,
        makeCommentForCoinTracking: (String) -> String
    ) -> CoinTrackingRow {
        guard let transaction = transactions.first(where: { $0.transactionID == transactionID }) else {
            return self
        }

        return CoinTrackingRow(
            type: transaction.type ?? type,
            buyAmount: transaction.buyAmount ?? buyAmount,
            buyCurrency: transaction.buyCurrency ?? buyCurrency,
            sellAmount: transaction.sellAmount ?? sellAmount,
            sellCurrency: transaction.sellCurrency ?? sellCurrency,
            fee: transaction.fee ?? fee,
            feeCurrency: transaction.feeCurrency ?? feeCurrency,
            exchange: transaction.exchange ?? exchange,
            group: transaction.group ?? group,
            comment: transaction.comment.map(makeCommentForCoinTracking) ?? comment,
            date: transaction.date ?? date
        )
    }
}

extension String {

    var formattedForCoinTrackingComment: String {
        guard let comment = trimmingCharacters(in: .whitespaces).nonBlank else {
            return ""
        }
        return comment.hasSuffix(".") ? comment + " " : comment + ". "
    }
}
