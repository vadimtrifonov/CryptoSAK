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

    @Argument(help: "Path to a CSV file with rewards from Subscan (https://polkadot.subscan.io/)")
    var rewardsCSVPath: String

    @Option(help: .startBlock(recordsName: "rewards"))
    var startBlock: UInt = 0

    @Option(help: .startDate(recordsName: "rewards"))
    var startDate: Date = .distantPast

    func run() throws {
        let rewards: [PolkadotReward] = try Self.decodePolkadotRewardsCSV(path: rewardsCSVPath)

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

    static func < (lhs: PolkadotReward, rhs: PolkadotReward) -> Bool {
        lhs.date < rhs.date
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
            .filter({ $0.date >= startDate })
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
            date: reward.date
        )
    }
}

extension Polkadot {
    static let coinTrackingSymbol = "DOT2"
}
