import CoinTrackingKit
import Combine
import Foundation
import FoundationExtensions
import HTTPClient
import LambdaKit
import TezosKit
import TzScanKit

struct TezosCapital {

    static func makeRewardsCSVEndpoint(address: String) throws -> Endpoint<[TezosCapitalRewardRow]> {
        try Endpoint(
            .get,
            url: "https://lukeknepper.com/delegate/getPoolCSV.php",
            parameters: ["address": address],
            parseResponse: { data, _ in
                let csv = String(data: data, encoding: .utf8) ?? ""
                let rows = csv.components(separatedBy: .newlines).filter({ !$0.isEmpty }).dropFirst()
                return try rows.map(TezosCapitalRewardRow.init)
            }
        )
    }
}

struct TzStats {

    struct CycleInfo: Decodable {
        let cycle: Int
        let start_time: String
        let end_time: String
    }

    /// https://api.tzstats.com/explorer/cycle/head
    static func makeCycleEndpoint(cycle: Int) throws -> Endpoint<CycleInfo> {
        try Endpoint(
            .get,
            url: URL(string: "https://api.tzstats.com/explorer/cycle/\(cycle)")!
        )
    }
}

struct TezosCycle {
    let cycle: Int
    let start: Date
    let end: Date
}

extension TezosCycle {
    private static let dateFormatter = ISO8601DateFormatter()

    init(cycleInfo: TzStats.CycleInfo) throws {
        self.init(
            cycle: cycleInfo.cycle,
            start: try Self.dateFormatter.date(from: cycleInfo.start_time),
            end: try Self.dateFormatter.date(from: cycleInfo.end_time)
        )
    }
}

struct TezosCapitalRewardRow {
    let cycle: Int
    let balance: Decimal
    let reward: Decimal
}

extension TezosCapitalRewardRow {
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

struct TezosCapitalStatementCommand {
    func execute(address: String, startDate _: Date) throws {
        var subscriptions = Set<AnyCancellable>()

        let rewards = try TezosCapital.makeRewardsCSVEndpoint(address: address)

        URLSession.shared.dataTaskPublisher(for: rewards)
            .flatMap { (rewards: [TezosCapitalRewardRow]) -> AnyPublisher<([TezosCapitalRewardRow], [TezosCycle]), Error> in
                rewards.reduce(Empty<TezosCycle, Error>().eraseToAnyPublisher()) { publisher, reward in
                    do {
                        let endpoint = try TzStats.makeCycleEndpoint(cycle: reward.cycle)
                        let cyclePublisher = URLSession.shared.dataTaskPublisher(for: endpoint).tryMap(TezosCycle.init)
                        return publisher.merge(with: cyclePublisher).eraseToAnyPublisher()
                    } catch {
                        return Fail(error: error).eraseToAnyPublisher()
                    }
                }
                .collect()
                .map({ (rewards, $0) })
                .eraseToAnyPublisher()
            }
            .map { rewards, cycles in
                rewards.compactMap { reward in
                    cycles.first(where: { $0.cycle == reward.cycle }).map({ (reward, $0) })
                }
                .filter({ $0.0.reward != 0 }) // filter out zero rewards
            }
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
                exit(0)
            }, receiveValue: { rewards in
                let rows = rewards.map { reward, cycle in
                    CoinTrackingRow.makeBondPoolReward(amount: reward.reward, poolName: "Tezos Capital", date: cycle.end)
                }
                do {
                    try write(rows: rows, filename: "TezosCapitalStatement")
                } catch {
                    print(error)
                }
            })
            .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension CoinTrackingRow {

    static func makeBondPoolReward(amount: Decimal, poolName: String, date: Date) -> CoinTrackingRow {
        self.init(
            type: .incoming(.mining),
            buyAmount: amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: poolName,
            group: "Bond Pool",
            comment: "Export",
            date: date
        )
    }
}

public struct Endpoint<Response> {

    public enum Error: Swift.Error {
        case invalidURLComponents(url: URL, parameters: [String: Any]?)
    }

    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    public let request: URLRequest
    public let parseResponse: (Data, URLResponse) throws -> Response

    public init(
        _ method: Method,
        url: URL,
        parameters: [String: Any]? = nil,
        parseResponse: @escaping (Data, URLResponse) throws -> Response
    ) throws {
        self.request = try Self.makeRequest(method, url: url, parameters: parameters)
        self.parseResponse = parseResponse
    }

    static func makeRequest(
        _ method: Method,
        url: URL,
        parameters: [String: Any]?
    ) throws -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = parameters?.toFormURLEncoded()

        guard let requestURL = components?.url else {
            throw Error.invalidURLComponents(url: url, parameters: parameters)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

func responsePublisher<Response>(
    dataTaskPublisher: (URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error>,
    endpoint: Endpoint<Response>
) -> AnyPublisher<Response, Error> {
    return dataTaskPublisher(endpoint.request).tryMap { data, response in
        try endpoint.parseResponse(data, response)
    }
    .eraseToAnyPublisher()
}

extension Endpoint where Response: Decodable {

    public init(
        _ method: Method,
        url: URL,
        parameters: [String: Any]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        try self.init(method, url: url, parameters: parameters) { data, _ in
            try decoder.decode(Response.self, from: data)
        }
    }
}

extension URLSession {

    func dataTaskPublisher<Response>(for endpoint: Endpoint<Response>) -> AnyPublisher<Response, Error> {
        dataTaskPublisher(for: endpoint.request).tryMap { data, response in
            try endpoint.parseResponse(data, response)
        }
        .eraseToAnyPublisher()
    }
}
