import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Polkadot
import PolkadotSubscan

struct PolkadotRewardsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "polkadot-rewards-statement")

    @Argument(help: "Polkadot address")
    var address: String

    @Argument(help: "Path to CSV file with rewards")
    var rewardsCSVPath: String

    @Option(default: Date.distantPast, help: "Oldest date from which rewards will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()
        let csvRows = try File.read(path: rewardsCSVPath).dropFirst() // drop header row
        let rewardRows = try csvRows.map(PolkadotRewardRow.init)

        Self.toRewardsWithTimestamps(
            rewardRows: rewardRows,
            fetchBlockTimestamp: SubscanPolkadotGateway().fetchBlockTimestamp,
            startDate: startDate
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { rewards in
            do {
                try File.write(
                    rows: Self.toCoinTrackingRows(address: self.address, rewards: rewards),
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

struct PolkadotRewardRow {
    let eventID: String
    let block: Int
    let extrinsicHash: String
    let action: String
    let value: Decimal
}

extension PolkadotRewardRow {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 5
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns)"
        }

        self.init(
            eventID: columns[0],
            block: try Int(string: columns[1]),
            extrinsicHash: columns[2],
            action: columns[3],
            value: try Decimal(string: columns[4]) / Polkadot.planckInDOT
        )
    }
}

extension PolkadotRewardsStatementCommand {

    static func toRewardsWithTimestamps(
        rewardRows: [PolkadotRewardRow],
        fetchBlockTimestamp: (Int) -> AnyPublisher<Date, Error>,
        startDate: Date
    ) -> AnyPublisher<[(PolkadotRewardRow, Date)], Error> {
        rewardRows.reduce(Empty().eraseToAnyPublisher()) { publisher, rewardRow in
            publisher
                .merge(with: fetchBlockTimestamp(rewardRow.block).map({ (rewardRow, $0) }))
                .eraseToAnyPublisher()
        }
        .filter({ _, timestamp in timestamp >= startDate })
        .collect()
        .eraseToAnyPublisher()
    }

    static func toCoinTrackingRows(
        address: String,
        rewards: [(PolkadotRewardRow, Date)]
    ) -> [CoinTrackingRow] {
        rewards.map { rewardRow, timestamp in
            CoinTrackingRow.makeReward(address: address, rewardRow: rewardRow, timestamp: timestamp)
        }
        .sorted(by: >)
    }
}

private extension CoinTrackingRow {

    static func makeReward(address: String, rewardRow: PolkadotRewardRow, timestamp: Date) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: rewardRow.value,
            buyCurrency: Polkadot.coinTrackingTicker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Polkadot \(address.prefix(8)).",
            group: "Reward",
            comment: "Export",
            date: timestamp,
            transactionID: ""
        )
    }
}

private extension Polkadot {
    static let coinTrackingTicker = "DOT2"
}
