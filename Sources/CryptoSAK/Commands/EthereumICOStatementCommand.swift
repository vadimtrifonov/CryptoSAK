import ArgumentParser
import CoinTracking
import Combine
import Ethereum
import Etherscan
import Foundation

struct EthereumICOStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "ethereum-ico-statement")

    @Argument(help: "Path to CSV file with information about ICO")
    var inputPath: String

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try File.read(path: inputPath)

        guard let ico = try csvRows.map(EthereumICO.init).first else {
            print("Nothing to export")
            Self.exit()
        }

        let gateway: EthereumGateway = makeEthereumGateway()

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
                try File.write(rows: rows, filename: "ICOExport")
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
        fetchTransaction: (_ hash: String) -> AnyPublisher<EthereumTransaction, Error>,
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
        fetchTransaction: (_ hash: String) -> AnyPublisher<EthereumTransaction, Error>
    ) -> AnyPublisher<[EthereumTransaction], Error> {
        ico.contributionHashes
            .map(fetchTransaction)
            .reduce(Empty().eraseToAnyPublisher()) { $0.merge(with: $1).eraseToAnyPublisher() }
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
            .filter { $0.token.symbol.uppercased() == ico.tokenSymbol.uppercased() }
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
        let totalContributionAmount = contibutionTransactions.reduce(0) { $0 + $1.amount }
        let totalTokenPayoutAmount = tokenPayoutTransactions.reduce(0) { $0 + $1.amount }

        let contibutionRows = contibutionTransactions.map { CoinTrackingRow.makeDeposit(ico: ico, transaction: $0) }
        let tokenPayoutRows = tokenPayoutTransactions.map { CoinTrackingRow.makeWithdrawal(ico: ico, transaction: $0) }

        let tradeRows = tokenPayoutTransactions.map { transaction -> CoinTrackingRow in
            let payoutPercent = transaction.amount / totalTokenPayoutAmount
            let proportionalContributionAmount = totalContributionAmount * payoutPercent
            return CoinTrackingRow.makeTrade(
                ico: ico,
                transaction: transaction,
                proportionalContributionAmount: proportionalContributionAmount
            )
        }

        return (contibutionRows + tradeRows + tokenPayoutRows).sorted(by: >)
    }
}

public struct EthereumICO {
    public let name: String
    public let tokenSymbol: String
    public let contributionHashes: [String]

    public init(
        name: String,
        tokenSymbol: String,
        contributionHashes: [String]
    ) {
        self.name = name
        self.tokenSymbol = tokenSymbol
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
            tokenSymbol: columns[1],
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
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: transaction.hash
        )
    }

    static func makeTrade(
        ico: EthereumICO,
        transaction: EthereumTokenTransaction,
        proportionalContributionAmount: Decimal
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .trade,
            buyAmount: transaction.amount,
            buyCurrency: transaction.token.symbol,
            sellAmount: proportionalContributionAmount,
            sellCurrency: Ethereum.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export",
            date: transaction.date,
            transactionID: ""
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
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date,
            transactionID: "" // CoinTracking considers transaction with the same ID as duplicate, even when one is deposit and another is withdrawal
        )
    }
}
