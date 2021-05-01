import CoinTracking
import Foundation

extension FileManager {

    var desktopDirectoryForCurrentUser: URL {
        let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first
        let url = path.map(URL.init(fileURLWithPath:))
        return url ?? FileManager.default.homeDirectoryForCurrentUser
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
