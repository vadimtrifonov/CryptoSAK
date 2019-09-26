import Foundation
import EtherscanKit
import EthereumKit
import FoundationExtensions

struct EthereumBalanceCommand {
    let gateway: EthereumGateway
    
    func execute(address: String) throws {
        let totalMeasurementStart = Date()
        let group = DispatchGroup()
        var results = [Result<[EthereumTransaction]>]()

        [gateway.fetchNormalTransactions,
         gateway.fetchInternalTransactions].forEach { fetch in
            group.enter()
            fetch(address) { result in
                results.append(result)
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            do {
                let transactions = try results.flatMap { try $0.unwrap() }
                let calculationMeasurementStart = Date()
                let balance = Self.balance(transactions: transactions, address: address)
                print("Calculation time \(Date().timeIntervalSince(calculationMeasurementStart)) seconds")
                print("Total time \(Date().timeIntervalSince(totalMeasurementStart)) seconds")
                print(balance)
                exit(0)
            } catch {
                print(error)
            }
        }

        RunLoop.main.run()
    }

    static func balance(transactions: [EthereumTransaction], address: String) -> EthereumBalance {
        // Relies on the `Hashable` implementation which takes into account only the transaction hash
        // Ethereum transaction with the same hash can be both outgoing and incoming
        // (address -> contract -> address, address -> address)
        let incoming = Set(transactions.filter { $0.isIncoming(address: address) })
        let outgoing = Set(transactions.filter { $0.isOutgoing(address: address) })
        let successfulOutgoing = outgoing.filter { $0.isSuccessful }

        let incomingAmount = incoming.reduce(0) { $0 + $1.amount }
        // Only successful transactions are debited
        let outgoingAmount = successfulOutgoing.reduce(0) { $0 + $1.amount }
        // Any outgoing transaction incures fees even if it fails
        let feesAmount = outgoing.reduce(0) { $0 + $1.fee }

        return EthereumBalance(
            balance: incomingAmount - outgoingAmount - feesAmount,
            incoming: incomingAmount,
            outgoing: outgoingAmount,
            fees: feesAmount,
            incomingCount: incoming.count,
            outgoingCount: successfulOutgoing.count,
            unsuccessfulOutgoingCount: outgoing.count - successfulOutgoing.count,
            feesCount: outgoing.count,
            totalUniqueCount: Set(transactions).count,
            totalCount: transactions.count
        )
    }
}

struct EthereumBalance {
    public let balance: Decimal
    public let incoming: Decimal
    public let outgoing: Decimal
    public let fees: Decimal
    public let incomingCount: Int
    public let outgoingCount: Int
    public let unsuccessfulOutgoingCount: Int
    public let feesCount: Int
    public let totalUniqueCount: Int
    public let totalCount: Int
}
