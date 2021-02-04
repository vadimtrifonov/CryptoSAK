import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Kusama
import KusamaSubscan

struct KusamaExtrinsicsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "kusama-extrinsics-statement",
        abstract: "Export Kusama extrinsics"
    )

    @Argument(help: "Kusama address")
    var address: String

    @Option(name: .customLong("known-transactions"), help: .knownTransactions)
    var knownTransactionsPath: String?

    @Option(help: .startBlock(eventsName: "extrinsics"))
    var startBlock: UInt = 0

    @Option(help: .startDate(eventsName: "extrinsics"))
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
        var rows = feeIncuringExtrinsics.map(CoinTrackingRow.makeFee)

        if let claimExtrinsic = claimExtrinsic {
            rows.append(CoinTrackingRow.makeClaim(extrinsic: claimExtrinsic))
        }

        return rows.overriden(with: knownTransactions).sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeClaim(extrinsic: KusamaExtrinsic) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .incoming(.deposit),
            buyAmount: 0,
            buyCurrency: Kusama.coinTrackingTicker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: extrinsic.fromNameForCoinTracking,
            group: "",
            comment: extrinsic.commentForCoinTracking,
            date: extrinsic.timestamp,
            transactionID: extrinsic.extrinsicHash
        )
    }

    static func makeFee(extrinsic: KusamaExtrinsic) -> CoinTrackingRow {
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
            comment: extrinsic.commentForCoinTracking,
            date: extrinsic.timestamp,
            transactionID: extrinsic.extrinsicHash
        )
    }
}

private extension KusamaExtrinsic {

    var fromNameForCoinTracking: String {
        "Kusama \(from.prefix(8))."
    }

    var commentForCoinTracking: String {
        CoinTrackingRow.makeComment(
            callFunction,
            "ID: \(extrinsicID)",
            eventName: "Extrinsic",
            eventID: extrinsicHash
        )
    }
}

extension Kusama {
    static let coinTrackingTicker = "KSM"
}
