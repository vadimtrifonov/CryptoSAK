import ArgumentParser
import CoinTracking
import Combine
import Ethereum
import EthereumEtherscan
import Foundation

struct EthereumTokensStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "ethereum-tokens-statement",
        abstract: "Export Ethereum-based token transactions",
        discussion: "Takes into account cancelled transactions (by excluding them, but including thier fees) and fees."
    )

    @Argument(help: "Ethereum address")
    var address: String

    @Flag(help: "Export token balances in a separate file")
    var balance = false

    @Option(
        name: .customLong("token-list"),
        help: .init(
            "Path to a CSV file with a list of tokens to be exported (other tokens will be ignored)",
            discussion: """
            - No header row
            - Format: <token-contract-address>,<token-symbol>
            """
        )
    )
    var tokenListPath: String?

    @Option(help: .startDate())
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let rows = try tokenListPath.map(FileManager.default.readLines(atPath:)) ?? []
        let tokenContractAddresses = rows.compactMap { row in
            row.split(separator: ",").map(String.init).first
        }

        let gateway = EtherscanEthereumGateway(apiKey: Config.etherscanAPIKey)
        gateway.fetchTokenTransactions(address: address, startDate: startDate)
            .map { transactions in
                Self.filteredTokenTransactions(
                    transactions: transactions,
                    tokenContractAddresses: tokenContractAddresses
                )
            }
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
                Self.exit()
            }, receiveValue: { [address] transactions in
                do {
                    let statement = EthereumTokensStatement(
                        transactions: transactions,
                        address: address
                    )
                    statement.balance.printRows()
                    if balance {
                        try FileManager.default.writeCSV(rows: statement.balance.toCSVRows(), filename: "EthereumTokenBalance", encoding: .utf8)
                    }
                    try FileManager.default.writeCSV(rows: statement.toCoinTrackingRows(), filename: "EthereumTokenStatement")
                } catch {
                    print(error)
                }
            })
            .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func filteredTokenTransactions(
        transactions: [EthereumTokenTransaction],
        tokenContractAddresses: [String]
    ) -> [EthereumTokenTransaction] {
        guard !tokenContractAddresses.isEmpty else {
            return transactions
        }

        return transactions.filter {
            tokenContractAddresses.map({ $0.lowercased() }).contains($0.token.contractAddress.lowercased())
        }
    }
}

private extension EthereumTokensBalance {
    func toCSVRows() -> [String] {
        balancePerToken.sorted(by: <).map { key, value in
            "\(key.contractAddress),\(key.symbol),\(key.name),\(value)"
        }
    }

    func printRows() {
        balancePerToken.sorted(by: <).forEach { key, value in
            print("\(key.symbol)\t\(value)")
        }
    }
}

private extension EthereumTokensStatement {
    func toCoinTrackingRows() -> [CoinTrackingRow] {
        let rows = incoming.map(CoinTrackingRow.makeDeposit)
            + outgoing.map(CoinTrackingRow.makeWithdrawal)
        return rows.sorted(by: >)
    }
}

private extension CoinTrackingRow {
    static func makeDeposit(transaction: EthereumTokenTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: transaction.token.symbol,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: transaction.destinationNameForCoinTracking,
            group: "",
            comment: Self.makeComment(eventID: transaction.hash),
            date: transaction.date
        )
    }

    static func makeWithdrawal(transaction: EthereumTokenTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: transaction.token.symbol,
            fee: 0,
            feeCurrency: "",
            exchange: transaction.sourceNameForCoinTracking,
            group: "",
            comment: Self.makeComment(eventID: transaction.hash),
            date: transaction.date
        )
    }
}

private extension EthereumTokenTransaction {
    var sourceNameForCoinTracking: String {
        "Ethereum \(from.prefix(8))."
    }

    var destinationNameForCoinTracking: String {
        "Ethereum \(to.prefix(8))."
    }
}
