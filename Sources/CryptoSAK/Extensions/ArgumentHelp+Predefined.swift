import ArgumentParser

extension ArgumentHelp {

    static var knownTransactions: ArgumentHelp {
        .init("Path to a CSV file with the list of known transactions")
    }

    static func startBlock(eventsName: String = "transactions") -> ArgumentHelp {
        .init(
            "Oldest block from which \(eventsName) will be exported",
            discussion: "Alternative to --start-date"
        )
    }

    static func startDate(eventsName: String = "transactions") -> ArgumentHelp {
        .init(
            "Oldest date from which \(eventsName) will be exported",
            discussion: """
            - Format: YYYY-MM-DD
            - Alternative to --start-block
            """
        )
    }
}
