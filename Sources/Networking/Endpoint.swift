import Combine
import Foundation

public struct Endpoint<ResponseBody> {

    public enum Error: Swift.Error {
        case invalidURLComponents(url: URL, queryItems: [String: Any]?)
    }

    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    public let request: URLRequest
    public let parseResponse: (Data, URLResponse) throws -> ResponseBody

    public init(
        _ method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: Data? = nil,
        parseResponse: @escaping (Data, URLResponse) throws -> ResponseBody
    ) throws {
        self.request = try Self.makeRequest(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body
        )
        self.parseResponse = parseResponse
    }

    private static func makeRequest(
        _ method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]?,
        body: Data? = nil
    ) throws -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = queryItems?.toFormURLEncoded()

        guard let requestURL = components?.url else {
            throw Error.invalidURLComponents(url: url, queryItems: queryItems)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        headers.forEach({ request.addValue($1, forHTTPHeaderField: $0) })
        request.httpBody = body

        return request
    }
}

extension Endpoint {

    public init<RequestBody: Encodable>(
        json method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: RequestBody? = nil,
        encoder: JSONEncoder = .init(),
        parseResponse: @escaping (Data, URLResponse) throws -> ResponseBody
    ) throws {
        let headers = headers.merging(["Content-Type": "application/json"]) { _, new in new }
        let body = try body.map({ try encoder.encode($0) })

        try self.init(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body,
            parseResponse: parseResponse
        )
    }
}

extension Endpoint where ResponseBody == Void {

    public init(
        _ method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: Data? = nil
    ) throws {
        try self.init(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body,
            parseResponse: { _, _ in () }
        )
    }

    public init<RequestBody: Encodable>(
        json method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: RequestBody? = nil,
        encoder: JSONEncoder = .init()
    ) throws {
        let headers = headers.merging(["Content-Type": "application/json"]) { _, new in new }
        let body = try body.map({ try encoder.encode($0) })

        try self.init(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body
        )
    }
}

extension Endpoint where ResponseBody: Decodable {

    public init(
        _ method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: Data? = nil,
        encoder _: JSONEncoder = .init(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        let headers = headers.merging(["Accept": "application/json"]) { _, new in new }

        try self.init(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body
        ) { data, _ in
            try decoder.decode(ResponseBody.self, from: data)
        }
    }

    public init<RequestBody: Encodable>(
        json method: Method,
        url: URL,
        headers: [String: String] = [:],
        queryItems: [String: Any]? = nil,
        body: RequestBody? = nil,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) throws {
        let headers = headers.merging(["Content-Type": "application/json"]) { _, new in new }
        let body = try body.map({ try encoder.encode($0) })

        try self.init(
            method,
            url: url,
            headers: headers,
            queryItems: queryItems,
            body: body,
            decoder: decoder
        )
    }
}
