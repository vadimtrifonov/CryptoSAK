import Foundation

public struct EthereumTokensBalance {
    public let balancePerToken: [EthereumToken: Decimal]
    public let incomingPerToken: [EthereumToken: Decimal]
    public let outgoingPerToken: [EthereumToken: Decimal]

    public init(
        incomingPerToken: [EthereumToken: [EthereumTokenTransaction]],
        outgoingPerToken: [EthereumToken: [EthereumTokenTransaction]]
    ) {
        let incomingPerToken = incomingPerToken.reduce(into: [:]) { incoming, pair in
            incoming[pair.key] = pair.value.reduce(0) { $0 + $1.amount }
        }

        let outgoingPerToken = outgoingPerToken.reduce(into: [:]) { outgoing, pair in
            outgoing[pair.key] = pair.value.reduce(0) { $0 + $1.amount }
        }

        let tokens = Set(incomingPerToken.keys).union(Set(outgoingPerToken.keys))
        let balancePerToken = tokens.reduce(into: [:]) { balance, token in
            balance[token] = incomingPerToken[token, default: 0] - outgoingPerToken[token, default: 0]
        }

        self.balancePerToken = balancePerToken
        self.incomingPerToken = incomingPerToken
        self.outgoingPerToken = outgoingPerToken
    }
}
