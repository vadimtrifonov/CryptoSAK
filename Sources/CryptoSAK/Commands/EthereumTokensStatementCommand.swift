import ArgumentParser
import CodableCSV
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

    @Flag(name: .customLong("balance"), help: "Export token balances in a separate file")
    var includeBalance = false

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

    @Option(name: .customLong("known-transactions"), help: .knownTransactions)
    var knownTransactionsPath: String?

    @Option(help: .startDate())
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let knownEthereumTokens = try tokenListPath.map(Self.decodeKnownEthereumTokensCSV) ?? []
        let knownTransactions = try knownTransactionsPath.map(KnownTransactionsCSVDecoder().decode) ?? []

        let gateway = EtherscanEthereumGateway(apiKey: Config.etherscanAPIKey)
        gateway.fetchTokenTransactions(address: address, startDate: startDate)
            .map { transactions in
                Self.filteredTokenTransactions(
                    transactions: transactions,
                    tokenContractAddresses: knownEthereumTokens.map(\.contractAddress)
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

                    let rows = statement.toCoinTrackingRows(knownTransactions: knownTransactions)
                    let overriden = rows.filter { row in
                        knownTransactions.contains(where: { $0.transactionID == row.transactionID })
                    }
                    print("Known transactions: \(knownTransactions.count)")
                    print("Overriden transactions: \(overriden.count)")

                    if includeBalance {
                        try Self.encodeEthereumTokensBalanceRecords(
                            records: statement.balance.toRecords(),
                            filename: "EthereumTokenBalance"
                        )
                    }
                    try CoinTrackingCSVEncoder().encode(
                        rows: rows,
                        filename: "EthereumTokenStatement"
                    )
                } catch {
                    print(error)
                }
            })
            .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func decodeKnownEthereumTokensCSV(path: String) throws -> [KnownEthereumToken] {
        try CSVDecoder().decode([KnownEthereumToken].self, from: URL(fileURLWithPath: path))
    }

    static func encodeEthereumTokensBalanceRecords(
        records: [EthereumTokensBalanceRecord],
        filename: String
    ) throws {
        let url = FileManager.default.desktopDirectoryForCurrentUser.appendingPathComponent(filename + ".csv")
        try CSVEncoder().encode(records, into: url)
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

struct KnownEthereumToken: Decodable {
    let contractAddress: String
    let symbol: String

    enum CodingKeys: Int, CodingKey {
        case contractAddress
        case symbol
    }
}

struct EthereumTokensBalanceRecord: Encodable {
    let contractAddress: String
    let symbol: String
    let name: String
    let balance: Decimal

    enum CodingKeys: Int, CodingKey {
        case contractAddress
        case symbol
        case name
        case balance
    }
}

private extension EthereumTokensBalance {

    func toRecords() -> [EthereumTokensBalanceRecord] {
        balancePerToken.sorted(by: <).map { key, value in
            EthereumTokensBalanceRecord(
                contractAddress: key.contractAddress,
                symbol: key.symbol,
                name: key.name,
                balance: value
            )
        }
    }

    func printRows() {
        balancePerToken.sorted(by: <).forEach { key, value in
            print("\(key.symbol)\t\(value)")
        }
    }
}

private extension EthereumTokensStatement {
    func toCoinTrackingRows(knownTransactions: [KnownTransaction]) -> [CoinTrackingRow] {
        let rows = incoming.map(CoinTrackingRow.makeDeposit)
            + outgoing.map(CoinTrackingRow.makeWithdrawal)
        return rows.overriden(with: knownTransactions).sorted(by: >)
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
            date: transaction.date,
            transactionID: transaction.hash
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
            date: transaction.date,
            transactionID: transaction.hash
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
