import Foundation

public struct EthereumToken {
    public let contractAddress: String
    public let name: String
    public let symbol: String
    public let decimalPlaces: Int

    public init(
        contractAddress: String,
        name: String,
        symbol: String,
        decimalPlaces: Int
    ) {
        self.contractAddress = contractAddress
        self.name = name
        self.symbol = symbol
        self.decimalPlaces = decimalPlaces
    }
}

extension EthereumToken: Equatable {
    public static func == (lhs: EthereumToken, rhs: EthereumToken) -> Bool {
        return lhs.contractAddress.lowercased() == rhs.contractAddress.lowercased()
    }
}

extension EthereumToken: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
    }
}

extension EthereumToken: Comparable {
    public static func < (lhs: EthereumToken, rhs: EthereumToken) -> Bool {
        return lhs.symbol.lowercased() < rhs.symbol.lowercased()
    }
}
