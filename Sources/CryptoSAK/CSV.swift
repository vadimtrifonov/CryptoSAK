import Foundation
import CoinTrackingKit

enum CSV {
    static func write(
        rows: [String],
        to directory: URL = FileManager.default.homeDirectoryForCurrentUser,
        filename: String = "Export",
        encoding: String.Encoding = .ascii
    ) throws {
        let csv = rows.joined(separator: "\n")
        let url = directory.appendingPathComponent(filename + ".csv")
        try csv.write(to: url, atomically: true, encoding: encoding)

        print("Done, wrote \(rows.count) rows to \(url.path)")
    }

    static func read(path: String) throws -> [String] {
        let url = URL(fileURLWithPath: path)
        let csv = try String(contentsOf: url)
        return csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}

func write(
    rows: [CoinTrackingRow],
    to directory: URL = FileManager.default.homeDirectoryForCurrentUser,
    filename: String = "CoinTracking"
) throws {
    let csv = CoinTrackingCSV.makeCSV(rows: rows)
    let url = directory.appendingPathComponent(filename + ".csv")
    try csv.write(to: url, atomically: true, encoding: .ascii)

    print("Done, wrote \(rows.count) rows to \(url.path)")
}
