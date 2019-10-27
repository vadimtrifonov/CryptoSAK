import CoinTrackingKit
import Combine
import EthereumKit
import EtherscanKit
import Foundation

struct EthereumICOStatementCommand {
    let gateway: EthereumGateway

    func execute(inputPath: String) throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try CSV.read(path: inputPath)

        guard let ico = try csvRows.map(ICO.init).first else {
            print("Nothing to export")
            exit(1)
        }

        Self.exportICOTransactions(
            ico: ico,
            fetchTransaction: gateway.fetchTransaction,
            fetchTokenTranactions: { self.gateway.fetchTokenTransactions(address: $0, startDate: Date.distantPast) }
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            exit(0)
        }, receiveValue: { rows in
            do {
                try write(rows: rows, filename: "ICOExport")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func exportICOTransactions(
        ico: ICO,
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
        ico: ICO,
        fetchTransaction: (_ hash: String) -> AnyPublisher<EthereumTransaction, Error>
    ) -> AnyPublisher<[EthereumTransaction], Error> {
        ico.contributionHashes
            .map(fetchTransaction)
            .reduce(Empty().eraseToAnyPublisher()) { $0.merge(with: $1).eraseToAnyPublisher() }
            .collect()
            .eraseToAnyPublisher()
    }

    static func fetchICOTokenPayoutTransactions(
        ico: ICO,
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
        ico: ICO,
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
        ico: ICO,
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
                contributionAmount: proportionalContributionAmount,
                tokenPayoutAmount: transaction.amount
            )
        }

        return (contibutionRows + tradeRows + tokenPayoutRows).sorted(by: >)
    }
}

public struct ICO {
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

private extension ICO {
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
    static func makeDeposit(ico: ICO, transaction: EthereumTransaction) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: transaction.amount,
            buyCurrency: "ETH",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export. Transaction: \(transaction.hash)",
            date: transaction.date
        )
    }

    static func makeTrade(
        ico: ICO,
        transaction: EthereumTokenTransaction,
        contributionAmount: Decimal,
        tokenPayoutAmount: Decimal
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .trade,
            buyAmount: tokenPayoutAmount,
            buyCurrency: transaction.token.symbol,
            sellAmount: contributionAmount,
            sellCurrency: "ETH",
            fee: 0,
            feeCurrency: "",
            exchange: ico.name,
            group: "",
            comment: "Export",
            date: transaction.date
        )
    }

    static func makeWithdrawal(
        ico: ICO,
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
            date: transaction.date
        )
    }
}
