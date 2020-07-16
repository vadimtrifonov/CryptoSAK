import Foundation
import FoundationExtensions

public struct IDEXBalanceRow {

    public enum OperationType: String {
        case withdrawal = "Withdrawal"
        case deposit = "Deposit"
    }

    public let date: Date
    public let currency: String
    public let operationType: OperationType
    public let amount: Decimal
    public let transactionHash: String
}

extension IDEXBalanceRow {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public init(tsvRow: String) throws {
        let columns = tsvRow.split(separator: Character("\t")).map(String.init)

        let expectedColumns = 7
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns)"
        }

        self.init(
            date: try IDEXBalanceRow.dateFormatter.date(from: columns[0]),
            currency: columns[1],
            operationType: try OperationType(string: columns[2]),
            amount: try Decimal(string: columns[4]),
            transactionHash: columns[6]
        )
    }
}

extension IDEXBalanceRow {

    public enum TransactionType {
        case ethereum
        case token
    }

    public var transactionType: TransactionType {
        currency == "ETH" ? .ethereum : .token
    }
}
