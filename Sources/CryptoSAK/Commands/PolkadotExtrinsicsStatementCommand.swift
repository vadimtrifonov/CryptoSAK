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
            CoinTrackingRow.makeFee(extrinsic: extrinsic)
        }

        if let claimExtrinsic = claimExtrinsic {
            rows.append(CoinTrackingRow.makeClaim(extrinsic: claimExtrinsic))
        }

        return rows.overriden(with: knownTransactions).sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeClaim(extrinsic: PolkadotExtrinsic) -> CoinTrackingRow {
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
            comment: extrinsic.commentForCoinTracking,
            date: extrinsic.timestamp,
            transactionID: extrinsic.extrinsicHash
        )
    }

    static func makeFee(extrinsic: PolkadotExtrinsic) -> CoinTrackingRow {
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
            comment: extrinsic.commentForCoinTracking,
            date: extrinsic.timestamp,
            transactionID: extrinsic.extrinsicHash
        )
    }
}

private extension PolkadotExtrinsic {

    var fromNameForCoinTracking: String {
        "Polkadot \(from.prefix(8))."
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
