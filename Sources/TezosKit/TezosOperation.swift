import Foundation

public protocol TezosOperation {
    var hash: String { get }
    var sourceAccount: String { get }
    var fee: Decimal { get }
    var timestamp: Date { get }
}
