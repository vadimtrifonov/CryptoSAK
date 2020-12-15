import CoinTracking
import Foundation
import FoundationExtensions

enum KnownTransactionsCSV {
    static let header = """
    "Type","Buy Amount","Buy Currency","Sell Amount","Sell Currency","Fee","Fee Currency","Exchange","Trade-Group","Comment","Date","Tx-ID"
    """

    static var numberOfColumns: Int {
        header.split(separator: ",").count
    }

    static func makeTransactions(rows: [String]) throws -> [KnownTransaction] {
        guard let header = rows.first else {
            throw "CSV file with known transactions is empty"
        }

        guard header == Self.header else {
            throw """
            Header is not matching the expected header.
            CSV header: \(header)
            Expected header: \(Self.header)
            """
        }

        return try rows.dropFirst().map(KnownTransaction.init)
    }
}

extension KnownTransaction {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        guard columns.count == KnownTransactionsCSV.numberOfColumns else {
            throw "Expected \(KnownTransactionsCSV.numberOfColumns) columns, got \(columns.count)"
        }

        var iterator = columns.makeIterator()

        self.init(
            type: try iterator.next()?.nonBlank.map { try CoinTrackingRow.TransactionType(rawValue: $0) },
            buyAmount: try iterator.next()?.nonBlank.map { try Decimal(string: $0) },
            buyCurrency: iterator.next()?.nonBlank,
            sellAmount: try iterator.next()?.nonBlank.map { try Decimal(string: $0) },
            sellCurrency: iterator.next()?.nonBlank,
            fee: try iterator.next()?.nonBlank.map { try Decimal(string: $0) },
            feeCurrency: iterator.next()?.nonBlank,
            exchange: iterator.next()?.nonBlank,
            group: iterator.next()?.nonBlank,
            comment: iterator.next()?.nonBlank,
            date: try iterator.next()?.nonBlank.map { try Self.dateFormatter.date(from: $0) },
            transactionID: iterator.next()?.nonBlank
        )
    }
}
