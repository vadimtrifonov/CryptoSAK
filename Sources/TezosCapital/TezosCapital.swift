import Foundation
import FoundationExtensions
import Networking

public struct TezosCapital {

    public struct Reward {
        public let cycle: Int
        public let balance: Decimal
        public let reward: Decimal
    }

    public static func makeRewardsCSVEndpoint(address: String) throws -> Endpoint<[Reward]> {
        try Endpoint(
            .get,
            url: "https://lukeknepper.com/delegate/getPoolCSV.php",
            queryItems: ["address": address],
            parseResponse: { data, _ in
                let csv = String(data: data, encoding: .utf8) ?? ""
                let rows = csv.components(separatedBy: .newlines).filter({ !$0.isEmpty }).dropFirst()
                return try rows.map(Reward.init)
            }
        )
    }
}

private extension TezosCapital.Reward {
    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        guard columns.count == 3 else {
            throw "Expected 3 columns, got \(columns)"
        }

        self.init(
            cycle: try Int(string: columns[0]),
            balance: try Decimal(string: columns[1]),
            reward: try Decimal(string: columns[2])
        )
    }
}
