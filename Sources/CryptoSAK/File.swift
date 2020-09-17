import CoinTracking
import Foundation

enum File {

    static func write(
        rows: [String],
        to directory: URL = FileManager.default.desktopDirectoryForCurrentUser,
        filename: String,
        filenameExtension: String = ".csv",
        encoding: String.Encoding = .ascii
    ) throws {
        let file = rows.joined(separator: "\n")
        let url = directory.appendingPathComponent(filename + filenameExtension)
        try file.write(to: url, atomically: true, encoding: encoding)
        print("Done, wrote \(rows.count) rows to \(url.path)")
    }

    static func read(path: String) throws -> [String] {
        let url = URL(fileURLWithPath: path)
        let file = try String(contentsOf: url)
        return file.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}

extension File {
    static func write(
        rows: [CoinTrackingRow],
        to directory: URL = FileManager.default.desktopDirectoryForCurrentUser,
        filename: String
    ) throws {

        let csv = CoinTrackingCSV.makeCSV(rows: rows)
        let url = directory.appendingPathComponent(filename + ".csv")
        try csv.write(to: url, atomically: true, encoding: .ascii)
        print("Done, wrote \(rows.count) rows to \(url.path)")
    }
}

private extension FileManager {

    var desktopDirectoryForCurrentUser: URL {
        let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first
        let url = path.map(URL.init(fileURLWithPath:))
        return url ?? FileManager.default.homeDirectoryForCurrentUser
    }
}
