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

    @Argument(help: "Path to a CSV file with rewards from Subscan (https://kusama.subscan.io/) OR a directory of such files")
    var rewardsCSVPath: String

    @Option(help: .startBlock(recordsName: "rewards"))
    var startBlock: Int = 0

    @Option(help: .startDate(recordsName: "rewards"))
    var startDate: Date = .distantPast

    func run() throws {
        let rewards: [KusamaReward]
        if FileManager.default.directoryExists(atPath: rewardsCSVPath) {
            let files = try FileManager.default.files(atPath: rewardsCSVPath, extension: "csv")
            rewards = try files.map(\.path).flatMap(Self.decodeKusamaRewardsCSV)
        } else {
            rewards = try Self.decodeKusamaRewardsCSV(path: rewardsCSVPath)
        }

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

struct ConvertPlanckToKSM: CustomDecoding {

    static func decode(from decoder: Decoder) throws -> Decimal {
        let planckAmount = try UInt(from: decoder)
        return Decimal(planckAmount) / Kusama.planckInKSM
    }
}

struct KusamaReward: Decodable, Comparable {
    let eventID: String
    let block: UInt
    @CustomCoded<SecondsSince1970> var blockTimestamp: Date
    private let time: String
    let extrinsicHash: String
    let action: String
    @CustomCoded<ConvertPlanckToKSM> var amount: Decimal

    enum CodingKeys: Int, CodingKey {
        case eventID
        case block
        case blockTimestamp
        case time
        case extrinsicHash
        case action
        case amount
    }

    static func < (lhs: KusamaReward, rhs: KusamaReward) -> Bool {
        lhs.blockTimestamp < rhs.blockTimestamp
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
            .filter({ $0.blockTimestamp >= startDate })
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
            date: reward.blockTimestamp
        )
    }
}
