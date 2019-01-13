import Foundation

public struct EthereumBalance {
    public let balance: Decimal
    public let incoming: Decimal
    public let outgoing: Decimal
    public let fees: Decimal
    public let incomingCount: Int
    public let outgoingCount: Int
    public let feesCount: Int
}

protocol EthereumBalanceCalculator {
    func calculate(address: String, handler: @escaping (Result<EthereumBalance>) -> Void)
}

public class EthereumBalanceCalculatorImpl: EthereumBalanceCalculator {
    private let etherscanGateway: EtherscanGateway
    
    public init(etherscanGateway: EtherscanGateway) {
        self.etherscanGateway = etherscanGateway
    }
    
    public func calculate(address: String, handler: @escaping (Result<EthereumBalance>) -> Void) {
        let group = DispatchGroup()
        var results = [Result<[Transaction]>]()
        
        [etherscanGateway.fetchNormalTransactions,
         etherscanGateway.fetchInternalTransactions].forEach { fetch in
            group.enter()
            fetch(address) { result in
                results.append(result)
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            do {
                let all = try results.flatMap({ try $0.unwrap() })
                let incoming = all.filter({ $0.to.lowercased() == address.lowercased() }).distinct
                let outgoing = all.filter({ $0.from.lowercased() == address.lowercased() }).distinct
                let successfulOutgoing = outgoing.filter({ $0.isSuccessful })
                
                let incomingAmount = incoming.reduce(0, { $0 + $1.amount })
                // Only successful transactions are debited
                let outgoingAmount = successfulOutgoing.reduce(0, { $0 + $1.amount })
                // Any outgoing transaction incures fees even if it fails
                let feesAmount = outgoing.reduce(0, { $0 + $1.fee })
                
                let balance = EthereumBalance(
                    balance: incomingAmount - outgoingAmount - feesAmount,
                    incoming: incomingAmount,
                    outgoing: outgoingAmount,
                    fees: feesAmount,
                    incomingCount: incoming.count,
                    outgoingCount: successfulOutgoing.count,
                    feesCount: outgoing.count
                )
                
                handler(.success(balance))
            } catch {
                handler(.failure(error))
            }
        }
    }
}
