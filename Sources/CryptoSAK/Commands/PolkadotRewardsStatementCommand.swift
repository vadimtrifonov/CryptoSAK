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

    @Argument(help: "Path to CSV file with rewards or directory of such files")
    var rewardsCSVPath: String

    @Option(help: "Oldest block from which rewards will be exported")
    var startBlock: UInt = 0

    @Option(help: "Oldest date from which rewards will be exported")
    var startDate: Date = .distantPast

    func run() throws {
        let csvRows: [String]
        if FileManager.default.directoryExists(atPath: rewardsCSVPath) {
            csvRows = try FileManager.default.files(atPath: rewardsCSVPath, extension: "csv")
                .flatMap { url in
                    try FileManager.default.readLines(at: url).dropFirst(withPrefix: "Event ID")
                }
        } else {
            csvRows = try FileManager.default.readLines(atPath: rewardsCSVPath).dropFirst(withPrefix: "Event ID")
        }

        let rewardRows = try csvRows.map(PolkadotRewardRow.init)

        let coinTrackingRows = Self.toCoinTrackingRows(
            address: address,
            rewards: rewardRows,
            startBlock: startBlock,
            startDate: startDate
        )

        do {
            try FileManager.default.writeCSV(
                rows: coinTrackingRows,
                filename: "PolkadotRewardsStatement"
            )
        } catch {
            print(error)
        }
    }
}

struct PolkadotRewardRow: Comparable {
    let eventID: String
    let block: UInt
    let blockTimestamp: Date
    let extrinsicHash: String
    let action: String
    let value: Decimal

    static func < (lhs: PolkadotRewardRow, rhs: PolkadotRewardRow) -> Bool {
        lhs.blockTimestamp < rhs.blockTimestamp
    }
}

extension PolkadotRewardRow {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 7
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns.count)"
        }

        self.init(
            eventID: columns[0],
            block: try UInt(string: columns[1]),
            blockTimestamp: try Date(timeIntervalSince1970: TimeInterval(string: columns[2])),
            extrinsicHash: columns[4],
            action: columns[5],
            value: try Decimal(string: columns[6]) / Polkadot.planckInDOT
        )
    }
}

extension PolkadotRewardsStatementCommand {

    static func toCoinTrackingRows(
        address: String,
        rewards: [PolkadotRewardRow],
        startBlock: UInt,
        startDate: Date
    ) -> [CoinTrackingRow] {
        rewards
            .sorted(by: >)
            .filter({ $0.block >= startBlock })
            .filter({ $0.blockTimestamp >= startDate })
            .map({ CoinTrackingRow.makeReward(address: address, rewardRow: $0) })
    }
}

private extension CoinTrackingRow {

    static func makeReward(address: String, rewardRow: PolkadotRewardRow) -> CoinTrackingRow {
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
            comment: "Export. ID: \(rewardRow.eventID). Extrinsic: \(rewardRow.extrinsicHash)",
            date: rewardRow.blockTimestamp
        )
    }
}

private extension Polkadot {
    static let coinTrackingTicker = "DOT2"
}
