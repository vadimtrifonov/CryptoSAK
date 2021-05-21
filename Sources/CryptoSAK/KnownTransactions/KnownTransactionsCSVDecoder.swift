import CodableCSV
import Foundation
import FoundationExtensions

struct KnownTransactionsCSVDecoder {

    private let decoder = CSVDecoder { configuration in
        configuration.headerStrategy = .firstLine
        configuration.dateStrategy = .formatted(RFC3339LocalTime.dateFormatter)
    }

    func decode(fromPath path: String) throws -> [KnownTransaction] {
        try decoder.decode([KnownTransaction].self, from: URL(fileURLWithPath: path))
    }
}
