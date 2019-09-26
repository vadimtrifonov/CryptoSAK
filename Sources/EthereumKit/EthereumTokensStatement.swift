import Foundation

public struct EthereumTokensStatement {
    public let incoming: [EthereumTokenTransaction]
    public let outgoing: [EthereumTokenTransaction]

    public var incomingPerToken: [EthereumToken: [EthereumTokenTransaction]] {
        Dictionary(grouping: incoming, by: { $0.token })
    }

    public var outgoingPerToken: [EthereumToken: [EthereumTokenTransaction]] {
        Dictionary(grouping: outgoing, by: { $0.token })
    }

    public var balance: EthereumTokensBalance {
        EthereumTokensBalance(incomingPerToken: incomingPerToken, outgoingPerToken: outgoingPerToken)
    }

    public init(transactions: [EthereumTokenTransaction], address: String) {
        /// Transactions with the same hash can have different token transfers
        let incoming = transactions.filter { $0.isIncoming(address: address) }
        let outgoing = transactions.filter { $0.isOutgoing(address: address) && $0.isSuccessful }

        self.incoming = incoming.sorted(by: >)
        self.outgoing = outgoing.sorted(by: >)
    }
}
