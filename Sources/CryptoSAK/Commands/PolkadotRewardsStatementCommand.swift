import ArgumentParser
import CodableCSV
import CoinTracking
import Combine
import Foundation
import FoundationExtensions
import Polkadot
import PolkadotSubscan

struct PolkadotRewardsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "polkadot-rewards-statement",
        abstract: "Export Polkadot rewards history",
        discussion: "Accepts Subscan (https://polkadot.subscan.io/) CSV rewards files"
    )

    @Argument(help: "Polkadot address")
    var address: String

    @Argument(help: "Path to a CSV file with rewards from Subscan (https://polkadot.subscan.io/) OR a directory of such files")
    var rewardsCSVPath: String

    @Option(help: .startBlock(recordsName: "rewards"))
    var startBlock: UInt = 0

    @Option(help: .startDate(recordsName: "rewards"))
    var startDate: Date = .distantPast

    func run() throws {
        let rewards: [PolkadotReward]
        if FileManager.default.directoryExists(atPath: rewardsCSVPath) {
            let files = try FileManager.default.files(atPath: rewardsCSVPath, extension: "csv")
            rewards = try files.map(\.path).flatMap(Self.decodePolkadotRewardsCSV)
        } else {
            rewards = try Self.decodePolkadotRewardsCSV(path: rewardsCSVPath)
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
                filename: "PolkadotRewardsStatement"
            )
        } catch {
            print(error)
        }
    }

    static func decodePolkadotRewardsCSV(path: String) throws -> [PolkadotReward] {
        try CSVDecoder(configuration: { $0.headerStrategy = .firstLine })
            .decode([PolkadotReward].self, from: URL(fileURLWithPath: path))
    }
}

struct PolkadotReward: Decodable, Comparable {
    let eventID: String
    let block: UInt
    @CustomCoded<SecondsSince1970> var blockTimestamp: Date
    private let time: String
    let extrinsicHash: String
    let action: String
    private let planckAmount: UInt

    var amount: Decimal {
        Decimal(planckAmount) / Polkadot.planckInDOT
    }

    enum CodingKeys: Int, CodingKey {
        case eventID
        case block
        case blockTimestamp
        case time
        case extrinsicHash
        case action
        case planckAmount
    }

    static func < (lhs: PolkadotReward, rhs: PolkadotReward) -> Bool {
        lhs.blockTimestamp < rhs.blockTimestamp
    }
}

extension PolkadotRewardsStatementCommand {

    static func toCoinTrackingRows(
        address: String,
        rewards: [PolkadotReward],
        startBlock: UInt,
        startDate: Date
    ) -> [CoinTrackingRow] {
        rewards
            .sorted(by: >)
            .filter({ $0.block >= startBlock })
            .filter({ $0.blockTimestamp >= startDate })
            .map({ CoinTrackingRow.makeReward(address: address, reward: $0) })
    }
}

private extension CoinTrackingRow {

    static func makeReward(address: String, reward: PolkadotReward) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: reward.amount,
            buyCurrency: Polkadot.coinTrackingSymbol,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Polkadot \(address.prefix(8)).",
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

extension Polkadot {
    static let coinTrackingSymbol = "DOT2"
}
