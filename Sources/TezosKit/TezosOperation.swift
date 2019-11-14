import Foundation

public protocol TezosOperation {
    var hash: String { get }
    var sender: String { get }
    var fee: Decimal { get }
    var burn: Decimal { get }
    var timestamp: Date { get }
}
