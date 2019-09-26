import Foundation

public enum CoinTrackingCSV {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public static func makeCSV(rows: [CoinTrackingRow]) -> String {
        let header = "\"Type\",\"Buy\",\"Cur.\",\"Sell\",\"Cur.\",\"Fee\",\"Cur.\",\"Exchange\",\"Group\",\"Comment\",\"Date\""
        let csvRows = [header] + rows.map(makeCSVRow)
        return csvRows.joined(separator: "\n")
    }

    public static func makeCSVRow(row: CoinTrackingRow) -> String {
        return [
            row.type.rawValue,
            row.buyAmount.description,
            row.buyCurrency,
            row.sellAmount.description,
            row.sellCurrency,
            row.fee.description,
            row.feeCurrency,
            row.exchange,
            row.group,
            row.comment,
            dateFormatter.string(from: row.date),
        ]
        .map { "\"\($0)\"" }
        .joined(separator: ",")
    }
}
