import CodableCSV
import Foundation

struct KnownTransactionsCSVDecoder {

    private let decoder = CSVDecoder { configuration in
        configuration.headerStrategy = .firstLine
    }

    func decode(fromPath path: String) throws -> [KnownTransaction] {
        try decoder.decode([KnownTransaction].self, from: URL(fileURLWithPath: path))
    }
}
