import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Polkadot
import PolkadotSubscan

struct PolkadotExtrinsicsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "polkadot-extrinsics-statement",
        abstract: "Export Polkadot extrinsics"
    )

    @Argument(help: "Polkadot address")
    var address: String

    @Option(name: .customLong("known-transactions"), help: "Path to a CSV file with the list of known transactions")
    var knownTransactionsPath: String?

    @Option(help: .init("Oldest block from which extrinsics will be exported", discussion: "An alternative option to the start date"))
    var startBlock: UInt = 0

    @Option(help: .init("Oldest date from which extrinsics will be exported", discussion: "Format: YYYY-MM-DD"))
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let knownTransactions = try knownTransactionsPath
            .map(FileManager.default.readLines(atPath:))
            .map(KnownTransactionsCSV.makeTransactions) ?? []

        Self.exportExtrinsicsStatement(
            address: address,
            fetchExtrinsics: SubscanPolkadotGateway().fetchExtrinsics,
            startBlock: startBlock,
            startDate: startDate
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { statement in
            do {
                try FileManager.default.writeCSV(
                    rows: statement.toCoinTrackingRows(knownTransactions: knownTransactions),
                    filename: "PolkadotRewardsStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension PolkadotExtrinsicsStatementCommand {

    static func exportExtrinsicsStatement(
        address: String,
        fetchExtrinsics: (String, UInt, Date) -> AnyPublisher<[PolkadotExtrinsic], Error>,
        startBlock: UInt,
        startDate: Date
    ) -> AnyPublisher<PolkadotExtrinsicsStatement, Error> {
        fetchExtrinsics(address, startBlock, startDate)
            .map(PolkadotExtrinsicsStatement.init)
            .eraseToAnyPublisher()
    }
}

extension PolkadotExtrinsicsStatement {

    func toCoinTrackingRows(knownTransactions: [KnownTransaction]) -> [CoinTrackingRow] {
        var rows = feeIncuringExtrinsics.map { extrinsic in
            CoinTrackingRow.makeFee(extrinsic: extrinsic, knownTransactions: knownTransactions)
        }

        if let claimExtrinsic = claimExtrinsic {
            rows.append(
                CoinTrackingRow.makeClaim(
                    extrinsic: claimExtrinsic,
                    knownTransactions: knownTransactions
                )
            )
        }

        return rows
    }
}

private extension CoinTrackingRow {

    static func makeClaim(
        extrinsic: PolkadotExtrinsic,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: 0,
            buyCurrency: Polkadot.coinTrackingTicker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: extrinsic.fromNameForCoinTracking,
            group: "Fee",
            comment: extrinsic.makeCommentForCoinTracking(),
            date: extrinsic.timestamp
        )
        .applyOverride(
            from: knownTransactions,
            withTransactionID: extrinsic.extrinsicHash,
            makeCommentForCoinTracking: extrinsic.makeCommentForCoinTracking
        )
    }

    static func makeFee(
        extrinsic: PolkadotExtrinsic,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: extrinsic.fee,
            sellCurrency: Polkadot.coinTrackingTicker,
            fee: 0,
            feeCurrency: "",
            exchange: extrinsic.fromNameForCoinTracking,
            group: "Fee",
            comment: extrinsic.makeCommentForCoinTracking(),
            date: extrinsic.timestamp
        )
        .applyOverride(
            from: knownTransactions,
            withTransactionID: extrinsic.extrinsicHash,
            makeCommentForCoinTracking: extrinsic.makeCommentForCoinTracking
        )
    }
}

private extension PolkadotExtrinsic {

    var fromNameForCoinTracking: String {
        "Polkadot \(from.prefix(8))."
    }

    func makeCommentForCoinTracking(comment: String = "") -> String {
        "Export. \(comment.formattedForCoinTrackingComment)\(callFunction). ID: \(extrinsicID). Extrinsic: \(extrinsicHash)"
    }
}
