import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Kusama
import KusamaSubscan

struct KusamaExtrinsicsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "kusama-extrinsics-statement")

    @Argument(help: "Kusama address")
    var address: String

    @Option(name: .customLong("known-transactions"), help: "Path to a CSV file with a list of known transactions")
    var knownTransactionsPath: String?

    @Option(help: "Oldest block from which rewards will be exported")
    var startBlock: UInt = 0

    @Option(help: "Oldest date from which extrinsics will be exported")
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        let knownTransactions = try knownTransactionsPath
            .map(FileManager.default.readLines(atPath:))
            .map(KnownTransactionsCSV.makeTransactions) ?? []

        Self.exportExtrinsicsStatement(
            address: address,
            fetchExtrinsics: SubscanKusamaGateway().fetchExtrinsics,
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
                    filename: "KusamaRewardsStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension KusamaExtrinsicsStatementCommand {

    static func exportExtrinsicsStatement(
        address: String,
        fetchExtrinsics: (String, UInt, Date) -> AnyPublisher<[KusamaExtrinsic], Error>,
        startBlock: UInt,
        startDate: Date
    ) -> AnyPublisher<KusamaExtrinsicsStatement, Error> {
        fetchExtrinsics(address, startBlock, startDate)
            .map(KusamaExtrinsicsStatement.init)
            .eraseToAnyPublisher()
    }
}

extension KusamaExtrinsicsStatement {

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
        extrinsic: KusamaExtrinsic,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: 0,
            buyCurrency: Kusama.coinTrackingTicker,
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
        extrinsic: KusamaExtrinsic,
        knownTransactions: [KnownTransaction]
    ) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: extrinsic.fee,
            sellCurrency: Kusama.coinTrackingTicker,
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

private extension KusamaExtrinsic {

    var fromNameForCoinTracking: String {
        "Kusama \(from.prefix(8))."
    }

    func makeCommentForCoinTracking(comment: String = "") -> String {
        "Export. \(comment.formattedForCoinTrackingComment)\(callFunction). ID: \(extrinsicID). Extrinsic: \(extrinsicHash)"
    }
}

extension Kusama {
    static let coinTrackingTicker = "KSM"
}
