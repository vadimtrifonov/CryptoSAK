import Combine
import Foundation

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
