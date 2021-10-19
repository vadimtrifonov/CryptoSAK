import ArgumentParser
import CodableCSV
import CoinTracking
import Combine
import Foundation
import FoundationExtensions
import Kusama

struct KusamaRewardsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "kusama-rewards-statement",
        abstract: "Export Kusama rewards history",
        discussion: "Accepts Subscan (https://kusama.subscan.io/) CSV rewards files"
    )

    @Argument(help: "Kusama address")
    var address: String

    @Argument(help: "Path to a CSV file with rewards from Subscan (https://kusama.subscan.io/)")
    var rewardsCSVPath: String

    @Option(help: .startBlock(recordsName: "rewards"))
    var startBlock: Int = 0

    @Option(help: .startDate(recordsName: "rewards"))
    var startDate: Date = .distantPast

    func run() throws {
        let rewards = try Self.decodeKusamaRewardsCSV(path: rewardsCSVPath)

        let coinTrackingRows = Self.toCoinTrackingRows(
            address: address,
            rewards: rewards,
            startBlock: startBlock,
            startDate: startDate
        )

        do {
            try CoinTrackingCSVEncoder().encode(
                rows: coinTrackingRows,
                filename: "KusamaRewardsStatement"
            )
        } catch {
            print(error)
        }
    }

    static func decodeKusamaRewardsCSV(path: String) throws -> [KusamaReward] {
        try CSVDecoder(configuration: { $0.headerStrategy = .firstLine })
            .decode([KusamaReward].self, from: URL(fileURLWithPath: path))
    }
}

struct KusamaReward: Decodable, Comparable {
    let eventID: String
    @CustomCoded<RFC3339UTC> var date: Date
    let block: UInt
    let extrinsicHash: String
    let amount: Decimal
    let action: String

    enum CodingKeys: Int, CodingKey {
        case eventID
        case date
        case block
        case extrinsicHash
        case amount
        case action
    }

    static func < (lhs: KusamaReward, rhs: KusamaReward) -> Bool {
        lhs.date < rhs.date
    }
}

extension KusamaRewardsStatementCommand {

    static func toCoinTrackingRows(
        address: String,
        rewards: [KusamaReward],
        startBlock: Int,
        startDate: Date
    ) -> [CoinTrackingRow] {
        rewards
            .sorted(by: >)
            .filter({ $0.eventID != "4077354-61" }) // Known invalid event ID
            .filter({ $0.block >= startBlock })
            .filter({ $0.date >= startDate })
            .map({ CoinTrackingRow.makeReward(address: address, reward: $0) })
    }
}

private extension CoinTrackingRow {

    static func makeReward(address: String, reward: KusamaReward) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: reward.amount,
            buyCurrency: Kusama.symbol,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Kusama \(address.prefix(8)).",
            group: "Reward",
            comment: Self.makeComment(
                "ID: \(reward.eventID)",
                eventName: "Extrinsic",
                eventID: reward.extrinsicHash
            ),
            date: reward.date
        )
    }
}
