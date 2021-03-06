import ArgumentParser
import CoinTracking
import Combine
import Ethereum
import EthereumEtherscan
import Foundation

struct EthereumICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "ethereum-ico-statement",
        abstract: "Export Ethereum-based ICO contribution, trade and payout transactions",
        discussion: """
        Derives the ICO address from the provided contribution transactions and looks for the payout transactions from it. \
        Creates a trade transaction for each contribution proportionally to the total amount of payouts.
        """
    )

    @Argument(
        help: .init(
            "Path to a CSV file with the information about the ICO",
            discussion: """
            - One row (no header row)
            - Format: <ico-name>,<token-contract-address>,<contribution-transaction-hash-1>,<contribution-transaction-hash-2>,...
            """
        )
    )
    var inputPath: String

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try FileManager.default.readLines(atPath: inputPath)

        guard let ico = try csvRows.map(EthereumICO.init).first else {
            print("Nothing to export")
            Self.exit()
        }

        let gateway = EtherscanEthereumGateway(apiKey: Config.etherscanAPIKey)

        Self.exportICOTransactions(
            ico: ico,
            fetchTransaction: gateway.fetchTransaction,
            fetchTokenTranactions: { gateway.fetchTokenTransactions(address: $0, startDate: Date.distantPast) }
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }

            Self.exit()
        }, receiveValue: { rows in
            do {
                try FileManager.default.writeCSV(rows: rows, filename: "EthereumICOExport")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension EthereumICOStatementCommand {

    static func exportICOTransactions(
        ico: EthereumICO,
        fetchTransaction: @escaping (_ hash: String) -> AnyPublisher<EthereumTransaction, Error>,
        fetchTokenTranactions: @escaping (_ address: String) -> AnyPublisher<[EthereumTokenTransaction], Error>
    ) -> AnyPublisher<[CoinTrackingRow], Error> {
        fetchContributionTransactions(
            ico: ico,
            fetchTransaction: fetchTransaction
        )
        .flatMap(maxPublishers: .max(1)) { contributionTransactions in
            fetchICOTokenPayoutTransactions(
                ico: ico,
                payoutAddress: contributionTransactions.first?.from ?? "",
                fetchTokenTranactions: fetchTokenTranactions
            )
            .map({ (contributionTransactions, $0) })
            .eraseToAnyPublisher()
        }
        .map { contributionTransactions, tokenPayoutTransactions in
            makeICOCoinTrackingRows(
                ico: ico,
                contibutionTransactions: contributionTransactions,
                tokenPayoutTransactions: tokenPayoutTransactions
            )
        }
        .eraseToAnyPublisher()
    }

    static func fetchContributionTransactions(
        ico: EthereumICO,
        fetchTransaction: @escaping (_ hash: String) -> AnyPublisher<EthereumTransaction, Error>
    ) -> AnyPublisher<[EthereumTransaction], Error> {
        ico.contributionHashes
            .reduce(Empty().eraseToAnyPublisher()) { publisher, hash in
                publisher
                    .append(fetchTransaction(hash))
                    // delay is need to avoid exhausting the Etherscan quota,
                    // this can be improved by implementing capping in Etherscan gateway
                    .delay(for: 0.5, scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
    }

    static func fetchICOTokenPayoutTransactions(
        ico: EthereumICO,
        payoutAddress: String,
        fetchTokenTranactions: @escaping (_ address: String) -> AnyPublisher<[EthereumTokenTransaction], Error>
    ) -> AnyPublisher<[EthereumTokenTransaction], Error> {
        fetchTokenTranactions(payoutAddress)
            .map { tokenTransactions in
                filterICOTokenPayoutTransactions(
                    ico: ico,
                    payoutAddress: payoutAddress,
                    tokenTransactions: tokenTransactions
                )
            }
            .eraseToAnyPublisher()
    }

    static func filterICOTokenPayoutTransactions(
        ico: EthereumICO,
        payoutAddress: String,
        tokenTransactions: [EthereumTokenTransaction]
    ) -> [EthereumTokenTransaction] {
        let icoTokenTransactions = tokenTransactions
            .filter { $0.token.contractAddress.uppercased() == ico.tokenContractAddress.uppercased() }
            .filter { $0.to.lowercased() == payoutAddress.lowercased() }
            .sorted(by: <)

        let firstPayout = icoTokenTransactions.first
        let allPayouts = icoTokenTransactions
            .filter { $0.from.lowercased() == firstPayout?.from.lowercased() }

        return allPayouts
    }

    static func makeICOCoinTrackingRows(
        ico: EthereumICO,
        contibutionTransactions: [EthereumTransaction],
        tokenPayoutTransactions: [EthereumTokenTransaction]
    ) -> [CoinTrackingRow] {
        guard let tokenSymbol = tokenPayoutTransactions.first?.token.symbol else {
            return []
        }

        let contibutionRows = contibutionTransactions.map { CoinTrackingRow.makeDeposit(ico: ico, transaction: $0) }
        let tokenPayoutRows = tokenPayoutTransactions.map { CoinTrackingRow.makeWithdrawal(ico: ico, transaction: $0) }

        let totalContributionAmount = contibutionTransactions.reduce(0) { $0 + $1.amount }
        let totalTokenPayoutAmount = tokenPayoutTransactions.reduce(0) { $0 + $1.amount }

        let tradeRows = contibutionTransactions.map { transaction -> CoinTrackingRow in
            let contributionPercent = transaction.amount / totalContributionAmount
            let proportionalPayoutAmount = totalTokenPayoutAmount * contributionPercent
            return CoinTrackingRow.makeTrade(
                ico: ico,
                contributionTransaction: transaction,
                proportionalPayoutAmount: proportionalPayoutAmount,
                tokenSymbol: tokenSymbol
            )
        }

        return (contibutionRows + tradeRows + tokenPayoutRows).sorted(by: >)
    }
}

public struct EthereumICO {
    public let name: String
    public let tokenContractAddress: String
    public let contributionHashes: [String]

    public init(
        name: String,
        tokenContractAddress: String,
        contributionHashes: [String]
    ) {
        self.name = name
        self.tokenContractAddress = tokenContractAddress
        self.contributionHashes = contributionHashes
    }
}

private extension EthereumICO {
    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        let minimumColumns = 3
        guard columns.count >= minimumColumns else {
            throw "Expected at least \(minimumColumns) columns, got \(columns)"
        }

        self.init(
            name: columns[0],
            tokenContractAddress: columns[1],
            contributionHashes: Array(columns.dropFirst(2))
        )
    }
}

private extension CoinTrackingRow {
    static func makeDeposit(ico: EthereumICO, transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: Ethereum.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: Self.makeComment(eventID: transaction.hash),
            date: transaction.date
        )
    }

    static func makeTrade(
        ico: EthereumICO,
        contributionTransaction: EthereumTransaction,
        proportionalPayoutAmount: Decimal,
        tokenSymbol: String
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .trade,
            buyAmount: proportionalPayoutAmount,
            buyCurrency: tokenSymbol,
            sellAmount: contributionTransaction.amount,
            sellCurrency: Ethereum.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: Self.makeComment(),
            date: contributionTransaction.date
        )
    }

    static func makeWithdrawal(
        ico: EthereumICO,
        transaction: EthereumTokenTransaction
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.withdrawal),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: transaction.amount,
            sellCurrency: transaction.token.symbol,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: Self.makeComment(eventID: transaction.hash),
            date: transaction.date
        )
    }
}
