import CoinTracking
import Foundation

extension FileManager {

    var desktopDirectoryForCurrentUser: URL {
        let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first
        let url = path.map(URL.init(fileURLWithPath:))
        return url ?? FileManager.default.homeDirectoryForCurrentUser
    }

    func readLines(at url: URL) throws -> [String] {
        let file = try String(contentsOf: url)
        return file.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    func readLines(atPath path: String) throws -> [String] {
        try readLines(at: URL(fileURLWithPath: path))
    }

    func writeCSV(
        rows: [String],
        to directory: URL = FileManager.default.desktopDirectoryForCurrentUser,
        filename: String,
        encoding: String.Encoding = .ascii
    ) throws {
        let file = rows.joined(separator: "\n")
        let url = directory.appendingPathComponent(filename + ".csv")
        try file.write(to: url, atomically: true, encoding: encoding)
        print("Done, wrote \(rows.count) rows to \(url.path)")
    }

    func writeCSV(
        rows: [CoinTrackingRow],
        to directory: URL = FileManager.default.desktopDirectoryForCurrentUser,
        filename: String
    ) throws {
        let csv = CoinTrackingCSV.makeCSV(rows: rows)
        let url = directory.appendingPathComponent(filename + ".csv")
        try csv.write(to: url, atomically: true, encoding: .ascii)
        print("Done, wrote \(rows.count) rows to \(url.path)")
    }

    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func files(atPath path: String, extension fileExtension: String? = nil) throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: nil,
                options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
            )
            .filter { !$0.hasDirectoryPath }
            .filter { url in
                guard let fileExtension = fileExtension else {
                    return true
                }
                return url.pathExtension == fileExtension
            }
    }
}
