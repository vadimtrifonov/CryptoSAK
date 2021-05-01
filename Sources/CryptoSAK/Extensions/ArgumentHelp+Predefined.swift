import ArgumentParser

extension ArgumentHelp {

    static var knownTransactions: ArgumentHelp {
        .init(
            "Path to a CSV file with the list of known transactions",
            discussion: """
            - Header: \(KnownTransaction.csvHeaders.joined(separator: ","))
            """
        )
    }

    static func startBlock(recordsName: String = "transactions") -> ArgumentHelp {
        .init(
            "Oldest block from which \(recordsName) will be exported",
            discussion: "Alternative to --start-date"
        )
    }

    static func startDate(recordsName: String = "transactions") -> ArgumentHelp {
        .init(
            "Oldest date from which \(recordsName) will be exported",
            discussion: """
            - Format: YYYY-MM-DD
            - Alternative to --start-block
            """
        )
    }
}
