import Foundation

protocol TzScanOperation: Decodable {
    func timestamp() throws -> Date
}

enum TzScanOperationType: String {
    case transaction = "Transaction"
    case delegation = "Delegation"
}
