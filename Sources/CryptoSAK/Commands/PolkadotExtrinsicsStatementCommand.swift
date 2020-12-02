import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Polkadot
import PolkadotSubscan

struct PolkadotExtrinsicsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "polkadot-extrinsics-statement")

    @Argument(help: "Polkadot address")
    var address: String

    @Option(help: "Oldest block from which rewards will be exported")
    var startBlock: UInt = 0

    @Option(help: "Oldest date from which extrinsics will be exported")
    var startDate: Date = .distantPast

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

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
                    rows: statement.toCoinTrackingRows(),
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

    func toCoinTrackingRows() -> [CoinTrackingRow] {
        feeIncuringExtrinsics.map(CoinTrackingRow.makeFee)
    }
}

private extension CoinTrackingRow {

    static func makeFee(extrinsic: PolkadotExtrinsic) -> CoinTrackingRow {
        CoinTrackingRow(
            type: .outgoing(.otherFee),
            buyAmount: 0,
            buyCurrency: "",
            sellAmount: extrinsic.fee,
            sellCurrency: Polkadot.ticker,
            fee: 0,
            feeCurrency: "",
            exchange: extrinsic.fromNameForCoinTracking,
            group: "Fee",
            comment: "Export. \(extrinsic.callFunction). ID: \(extrinsic.id). Extrinsic: \(extrinsic.extrinsicHash)",
            date: extrinsic.timestamp
        )
    }
}

private extension PolkadotExtrinsic {

    var fromNameForCoinTracking: String {
        "Polkadot \(from.prefix(8))."
    }
}