import Foundation

extension CoinTrackingRow {
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    var csvRow: String {
        return [
            type.rawValue,
            buyAmount.description,
            buyCurrency,
            sellAmount.description,
            sellCurrency,
            fee.description,
            feeCurrency,
            exchange,
            group,
            comment,
            CoinTrackingRow.dateFormatter.string(from: date),
        ]
        .map({ "\"\($0)\"" })
        .joined(separator: ",")
    }
    
    public static func makeCSV(rows: [CoinTrackingRow]) -> String {
        let header = "\"Type\",\"Buy\",\"Cur.\",\"Sell\",\"Cur.\",\"Fee\",\"Cur.\",\"Exchange\",\"Group\",\"Comment\",\"Date\""
        var rows = rows.map({ $0.csvRow })
        rows.insert(header, at: 0)
        return rows.joined(separator: "\n")
    }
}
