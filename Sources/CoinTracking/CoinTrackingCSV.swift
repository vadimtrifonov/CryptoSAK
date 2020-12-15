import Foundation

public enum CoinTrackingCSV {
    public static let header = """
    "Type","Buy Amount","Buy Currency","Sell Amount","Sell Currency","Fee","Fee Currency","Exchange","Trade-Group","Comment","Date"
    """

    public static func makeCSV(rows: [CoinTrackingRow]) -> String {
        let csvRows = [Self.header] + rows.map { $0.toCSVRow() }
        return csvRows.joined(separator: "\n")
    }
}

extension CoinTrackingRow {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public func toCSVRow() -> String {
        [
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
            Self.dateFormatter.string(from: date),
        ]
        .map { "\"\($0)\"" }
        .joined(separator: ",")
    }
}
