import CoinTrackingKit
import Combine
import Foundation
import FoundationExtensions
import HTTPClient
import LambdaKit
import TezosKit
import TzScanKit

struct TezosCapital {

    static func rewardsCSV(address: String) throws -> Endpoint<[TezosCapitalRewardRow]> {
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

struct TezosCapitalRewardRow {
    let cycle: String
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
            cycle: columns[0],
            balance: try Decimal(string: columns[1]),
            reward: try Decimal(string: columns[2])
        )
    }
}

struct TezosBondPoolStatementCommand {
    func execute(address: String, startDate _: Date) throws {
        var subscriptions = Set<AnyCancellable>()

        let endpoint = try TezosCapital.rewardsCSV(address: address)

        URLSession.shared.dataTaskPublisher(for: endpoint)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
                exit(0)
            }, receiveValue: { rows in
                print(rows)
                print("Done")
            })
            .store(in: &subscriptions)

        RunLoop.main.run()
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
