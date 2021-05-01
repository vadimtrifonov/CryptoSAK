import CoinTracking

extension Array where Element == CoinTrackingRow {

    func overriden(with knownTransactions: [KnownTransaction]) -> [CoinTrackingRow] {
        map { transaction in
            knownTransactions
                .first(where: { $0.transactionID == transaction.transactionID })
                .map { transaction.overriden(with: $0) }
                ?? transaction
        }
    }
}

extension CoinTrackingRow {
    static let exportCommentPrefix = "Export"

    static func makeComment(
        _ description: String...,
        eventName: String = "Transaction",
        eventID: String = ""
    ) -> String {
        var substrings = [Self.exportCommentPrefix]

        description.compactMap(\.nonBlank).forEach { description in
            substrings.append(description.formattedForCoinTrackingComment)
        }

        if !eventID.isBlank {
            substrings.append("\(eventName): \(eventID)")
        }

        if substrings.count > 1 {
            substrings[0].append(".")
        }

        return substrings.joined(separator: " ")
    }

    func overriden(with transaction: KnownTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: transaction.type ?? type,
            buyAmount: transaction.buyAmount ?? buyAmount,
            buyCurrency: transaction.buyCurrency ?? buyCurrency,
            sellAmount: transaction.sellAmount ?? sellAmount,
            sellCurrency: transaction.sellCurrency ?? sellCurrency,
            fee: transaction.fee ?? fee,
            feeCurrency: transaction.feeCurrency ?? feeCurrency,
            exchange: transaction.exchange ?? exchange,
            group: transaction.group ?? group,
            comment: transaction.insertAdditionalComment(to: comment),
            date: transaction.date ?? date,
            transactionID: transactionID
        )
    }
}

private extension KnownTransaction {

    func insertAdditionalComment(to originalComment: String) -> String {
        guard let additionalComment = comment?.nonBlank else {
            return originalComment
        }

        var substrings = originalComment.components(separatedBy: " ")

        guard
            let prefix = substrings.first,
            prefix.hasPrefix(CoinTrackingRow.exportCommentPrefix)
        else {
            Swift.assertionFailure("""
            Expected to find \"\(CoinTrackingRow.exportCommentPrefix)\" prefix in front of the comment: \(originalComment)
            """)
            return originalComment
        }

        if !prefix.hasSuffix(".") {
            substrings[0].append(".")
        }

        substrings.insert(additionalComment.formattedForCoinTrackingComment, at: 1)

        return substrings.joined(separator: " ")
    }
}

private extension String {

    var formattedForCoinTrackingComment: String {
        guard let comment = trimmingCharacters(in: .whitespaces).nonBlank else {
            return ""
        }
        return comment.hasSuffix(".") ? comment : comment.appending(".")
    }
}
