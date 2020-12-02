import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Kusama

struct KusamaRewardsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "kusama-rewards-statement")

    @Argument(help: "Kusama address")
    var address: String

    @Argument(help: "Path to CSV file with rewards or directory of such files")
    var rewardsCSVPath: String

    @Option(help: "Oldest block from which rewards will be exported")
    var startBlock: Int = 0

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

        let rewardRows = try csvRows.map(KusamaRewardRow.init)

        let coinTrackingRows = Self.toCoinTrackingRows(
            address: address,
            rewards: rewardRows,
            startBlock: startBlock,
            startDate: startDate
        )

        do {
            try FileManager.default.writeCSV(
                rows: coinTrackingRows,
                filename: "KusamaRewardsStatement"
            )
        } catch {
            print(error)
        }
    }
}

struct KusamaRewardRow: Comparable {
    let eventID: String
    let block: Int
    let blockTimestamp: Date
    let extrinsicHash: String
    let action: String
    let value: Decimal

    static func < (lhs: KusamaRewardRow, rhs: KusamaRewardRow) -> Bool {
        lhs.blockTimestamp < rhs.blockTimestamp
    }
}

extension KusamaRewardRow {

    init(csvRow: String) throws {
        let columns = csvRow.split(separator: Character(",")).map(String.init)

        let expectedColumns = 7
        guard columns.count == expectedColumns else {
            throw "Expected \(expectedColumns) columns, got \(columns.count)"
        }

        self.init(
            eventID: columns[0],
            block: try Int(string: columns[1]),
            blockTimestamp: try Date(timeIntervalSince1970: TimeInterval(string: columns[2])),
            extrinsicHash: columns[4],
            action: columns[5],
            value: try Decimal(string: columns[6]) / Kusama.planckInKSM
        )
    }
}

extension KusamaRewardsStatementCommand {

    static func toCoinTrackingRows(
        address: String,
        rewards: [KusamaRewardRow],
        startBlock: Int,
        startDate: Date
    ) -> [CoinTrackingRow] {
        rewards
            .sorted(by: >)
            .filter({ $0.eventID != "4077354-61" }) // Known invalid event ID
            .filter({ $0.block >= startBlock })
            .filter({ $0.blockTimestamp >= startDate })
            .map({ CoinTrackingRow.makeReward(address: address, rewardRow: $0) })
    }
}

private extension CoinTrackingRow {

    static func makeReward(address: String, rewardRow: KusamaRewardRow) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: rewardRow.value,
            buyCurrency: Kusama.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Kusama \(address.prefix(8)).",
            group: "Reward",
            comment: "Export. Extrinsic: \(rewardRow.extrinsicHash). Event ID: \(rewardRow.eventID)",
            date: rewardRow.blockTimestamp
        )
    }
}
