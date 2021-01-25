import ArgumentParser
import CoinTracking
import Combine
import Ethereum
import EthereumEtherscan
import Foundation
import IDEX
import Lambda

struct IDEXBalanceStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "idex-balance-statement",
        abstract: "Convert IDEX balance history",
        discussion: "Takes into account Ethereum withdrwal fees"
    )

    @Argument(
        help: .init(
            "Path to a TSV file with the IDEX balance history",
            discussion: """
            - Balance history should be manually copied from the website: open the balance history page, select all, and copy to a tab delimited TSV file.
            - Append the transaction hash to every row (Ethereum withdrawal fees will reported).
            - Include the header row
            - Format: <date> <asset> <type> <name> <amount> <status> <transaction>
            """
        )
    )
    var tsvPath: String

    func run() throws {
        let tsvRows = try FileManager.default.readLines(atPath: tsvPath).dropFirst() // drop header row
        let balanceRows = try tsvRows.map(IDEXBalanceRow.init)

        var subscriptions = Set<AnyCancellable>()
        let gateway = EtherscanGateway(apiKey: Config.etherscanAPIKey)

        Self.exportStatement(
            rows: balanceRows,
            fetchInternalTransaction: gateway.fetchInternalTransaction
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { rows in
            do {
                try FileManager.default.writeCSV(rows: rows, filename: "IDEXBalanceStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func exportStatement(
        rows: [IDEXBalanceRow],
        fetchInternalTransaction: @escaping (_ hash: String) -> AnyPublisher<EthereumInternalTransaction, Error>
    ) -> AnyPublisher<[CoinTrackingRow], Error> {
        let groupedRows = Dictionary(grouping: rows, by: { $0.operationType })
        let deposits = groupedRows[.deposit, default: []]
        let withdrawals = groupedRows[.withdrawal, default: []]

        return recursivelyFetchTransactionsForRows(
            rowsIterator: withdrawals.makeIterator(),
            accumulatedRowsWithTransactions: [],
            fetchTransaction: fetchTransaction(fetchInternalTransaction: fetchInternalTransaction)
        )
        .map { withdrawalsWithTransactions in
            IDEXBalanceStatement(
                deposits: deposits,
                withdrawalsWithTransactions: withdrawalsWithTransactions
            )
            .operations.map(CoinTrackingRow.init).sorted(by: >)
        }
        .eraseToAnyPublisher()
    }

    static func recursivelyFetchTransactionsForRows(
        rowsIterator: IndexingIterator<[IDEXBalanceRow]>,
        accumulatedRowsWithTransactions: [(IDEXBalanceRow, IDEXBalanceTransaction)],
        fetchTransaction: @escaping (_ row: IDEXBalanceRow) -> AnyPublisher<IDEXBalanceTransaction, Error>,
        delayForEachRow: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.25)
    ) -> AnyPublisher<[(IDEXBalanceRow, IDEXBalanceTransaction)], Error> {
        var rowsIterator = rowsIterator
        guard let row = rowsIterator.next() else {
            return Just(accumulatedRowsWithTransactions).mapError(toError).eraseToAnyPublisher()
        }

        return fetchTransaction(row)
            .map { transaction in
                accumulateRowsWithTransactions(
                    row: row,
                    transaction: transaction,
                    accumulatedRowsWithTransactions: accumulatedRowsWithTransactions
                )
            }
            .delay(for: delayForEachRow, scheduler: DispatchQueue.main)
            .flatMap(maxPublishers: .max(1)) { accumulatedRowsWithTransactions -> AnyPublisher<[(IDEXBalanceRow, IDEXBalanceTransaction)], Error> in
                recursivelyFetchTransactionsForRows(
                    rowsIterator: rowsIterator,
                    accumulatedRowsWithTransactions: accumulatedRowsWithTransactions,
                    fetchTransaction: fetchTransaction
                )
            }
            .eraseToAnyPublisher()
    }

    static func accumulateRowsWithTransactions(
        row: IDEXBalanceRow,
        transaction: IDEXBalanceTransaction,
        accumulatedRowsWithTransactions: [(IDEXBalanceRow, IDEXBalanceTransaction)]
    ) -> [(IDEXBalanceRow, IDEXBalanceTransaction)] {
        accumulatedRowsWithTransactions + [(row, transaction)]
    }

    static func fetchTransaction(
        fetchInternalTransaction: @escaping (_ hash: String) -> AnyPublisher<EthereumInternalTransaction, Error>
    ) -> (_ row: IDEXBalanceRow) -> AnyPublisher<IDEXBalanceTransaction, Error> {
        { row in
            switch row.transactionType {
            case .ethereum:
                return fetchInternalTransaction(row.transactionHash)
                    .map(IDEXBalanceTransaction.internalEthereum)
                    .eraseToAnyPublisher()
            case .token:
                return Just(IDEXBalanceTransaction.token)
                    .mapError(toError)
                    .eraseToAnyPublisher()
            }
        }
    }
}

struct IDEXBalanceOperation {

    public enum OperationType {
        case deposit
        case withdrawal
        case fee
    }

    public let type: OperationType
    public let date: Date
    public let amount: Decimal
    public let currency: String
    public let transactionHash: String
}

enum IDEXBalanceTransaction {
    case internalEthereum(EthereumInternalTransaction)
    case token // token transaction not yet supported
}

struct IDEXBalanceStatement {
    let operations: [IDEXBalanceOperation]

    init(
        deposits: [IDEXBalanceRow] = [],
        withdrawalsWithTransactions: [(IDEXBalanceRow, IDEXBalanceTransaction)]
    ) {
        self.operations = Self.transformDepositsToOperations(deposits: deposits)
            + Self.transformWithrawalsToOperations(withdrawals: withdrawalsWithTransactions)
    }

    static func transformDepositsToOperations(deposits: [IDEXBalanceRow]) -> [IDEXBalanceOperation] {
        deposits.map { row in
            IDEXBalanceOperation(
                type: .deposit,
                date: row.date,
                amount: row.amount,
                currency: row.currency,
                transactionHash: row.transactionHash
            )
        }
    }

    static func transformWithrawalsToOperations(
        withdrawals: [(IDEXBalanceRow, IDEXBalanceTransaction)]
    ) -> [IDEXBalanceOperation] {
        withdrawals.flatMap { row, transaction -> [IDEXBalanceOperation] in
            switch transaction {
            case let .internalEthereum(transaction):
                let withdrawal = IDEXBalanceOperation(
                    type: .withdrawal,
                    date: row.date,
                    amount: transaction.amount,
                    currency: row.currency,
                    transactionHash: row.transactionHash
                )
                let fee = IDEXBalanceOperation(
                    type: .fee,
                    date: row.date,
                    amount: row.amount - transaction.amount,
                    currency: row.currency,
                    transactionHash: row.transactionHash
                )
                return [withdrawal, fee]

            case .token:
                let withdrawal = IDEXBalanceOperation(
                    type: .withdrawal,
                    date: row.date,
                    amount: row.amount,
                    currency: row.currency,
                    transactionHash: row.transactionHash
                )
                return [withdrawal]
            }
        }
    }
}

private extension CoinTrackingRow {

    init(idexBalanceOperation: IDEXBalanceOperation) {
        switch idexBalanceOperation.type {
        case .withdrawal:
            self.init(
                type: .outgoing(.withdrawal),
                buyAmount: 0,
                buyCurrency: "",
                sellAmount: idexBalanceOperation.amount,
                sellCurrency: idexBalanceOperation.currency,
                fee: 0,
                feeCurrency: "",
                exchange: "IDEX",
                group: "",
                comment: "Export. Transaction: \(idexBalanceOperation.transactionHash)",
                date: idexBalanceOperation.date
            )
        case .deposit:
            self.init(
                type: .incoming(.deposit),
                buyAmount: idexBalanceOperation.amount,
                buyCurrency: idexBalanceOperation.currency,
                sellAmount: 0,
                sellCurrency: "",
                fee: 0,
                feeCurrency: "",
                exchange: "IDEX",
                group: "",
                comment: "Export. Transaction: \(idexBalanceOperation.transactionHash)",
                date: idexBalanceOperation.date
            )
        case .fee:
            self.init(
                type: .outgoing(.otherFee),
                buyAmount: 0,
                buyCurrency: "",
                sellAmount: idexBalanceOperation.amount,
                sellCurrency: idexBalanceOperation.currency,
                fee: 0,
                feeCurrency: "",
                exchange: "IDEX",
                group: "Fee",
                comment: "Export",
                date: idexBalanceOperation.date
            )
        }
    }
}
