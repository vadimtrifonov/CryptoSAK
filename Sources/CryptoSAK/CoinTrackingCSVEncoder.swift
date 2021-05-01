import CodableCSV
import CoinTracking
import Foundation

struct CoinTrackingCSVEncoder {

    let encoder = CSVEncoder { configuration in
        configuration.headers = CoinTrackingRow.csvHeaders
        configuration.bomStrategy = .never
    }

    func encode(
        rows: [CoinTrackingRow],
        directory: URL = FileManager.default.desktopDirectoryForCurrentUser,
        filename: String
    ) throws {
        let url = directory.appendingPathComponent(filename + ".csv")
        print("Writing \(rows.count) rows to \(url.path)")
        try encoder.encode(rows, into: url)
    }
}
