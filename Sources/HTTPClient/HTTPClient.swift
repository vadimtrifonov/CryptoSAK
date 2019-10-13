import Combine
import Foundation
import os.log

public enum HTTPClientError: Error {
    case invalidURLComponents(baseURL: URL, path: String, parameters: [String: Any]?)
}

public protocol HTTPClient {
    func get<Response: Decodable>(
        path: String,
        parameters: [String: Any]
    ) -> AnyPublisher<Response, Error>
}

public final class DefaultHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, urlSession: URLSession) {
        self.baseURL = baseURL
        self.session = urlSession
    }

    public func get<Response: Decodable>(
        path: String,
        parameters: [String: Any]
    ) -> AnyPublisher<Response, Error> {
        do {
            let request = try Self.makeRequest(baseURL: baseURL, path: path, parameters: parameters)
            #if DEBUG
                os_log("%@", "\(request.hashValue) GET: \(path) \(parameters)")
                os_log("%@", "\(request.hashValue) GET: \(request.url?.absoluteString ?? "")")
            #endif
            return executeRequest(request: request)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func download(path: String, parameters: [String: Any]) -> AnyPublisher<Data, Error> {
        do {
            let request = try Self.makeRequest(baseURL: baseURL, path: path, parameters: parameters)
            return session.downloadTaskPublisher(with: request).tryMap { url, _ in
                #if DEBUG
                    os_log("%@", "\(request.hashValue) RESPONSE: \(String(describing: try? Data(contentsOf: url).description))")
                #endif
                return try Data(contentsOf: url)
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func executeRequest<T: Decodable>(request: URLRequest) -> AnyPublisher<T, Error> {
        return session.dataTaskPublisher(for: request).tryMap { data, _ in
            #if DEBUG
                os_log("%@", "\(request.hashValue) RESPONSE: \(data.description)")
            #endif

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                #if DEBUG
                    os_log("%@", "\(request.hashValue) DECODING FAILURE: \(String(describing: error))")
                #endif
                throw error
            }
        }
        .handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                #if DEBUG
                    os_log("%@", "\(request.hashValue) ERROR: \(error.localizedDescription)")
                #endif
            }
        })
        .eraseToAnyPublisher()
    }

    static func makeRequest(
        _ method: String = "GET",
        baseURL: URL,
        path: String,
        parameters: [String: Any]?
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.percentEncodedPath = path
        components?.percentEncodedQuery = parameters?.toFormURLEncoded()

        guard let url = components?.url else {
            throw HTTPClientError.invalidURLComponents(
                baseURL: baseURL,
                path: path,
                parameters: parameters
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

private extension Data {
    var description: String {
        do {
            let json = try JSONSerialization.jsonObject(with: self)
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return String(data: self, encoding: .utf8) ?? ""
        }
    }
}

extension URLSession {

    func downloadTaskPublisher(with request: URLRequest) -> DownloadTaskPublisher {
        return DownloadTaskPublisher(request: request, session: self)
    }
}

public struct DownloadTaskPublisher: Publisher {
    public typealias Output = (url: URL, response: URLResponse)
    public typealias Failure = Error

    public let request: URLRequest
    public let session: URLSession

    public init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = DownloadTaskSubscription(subscriber: subscriber, request: request, session: session)
        subscriber.receive(subscription: subscription)
    }
}

private final class DownloadTaskSubscription<S: Subscriber>: Subscription
    where S.Input == (url: URL, response: URLResponse), S.Failure == Error {
    let combineIdentifier = CombineIdentifier()

    private var subscriber: S?
    private var task: URLSessionDownloadTask?

    init(subscriber: S, request: URLRequest, session: URLSession) {
        self.subscriber = subscriber
        self.task = Self.makeDownloadTask(subscriber: subscriber, request: request, session: session)
    }

    func request(_ demand: Subscribers.Demand) {
        if demand != .none {
            task?.resume()
        }
    }

    func cancel() {
        task?.cancel(byProducingResumeData: { _ in })
        task = nil
        subscriber = nil
    }

    private static func makeDownloadTask(
        subscriber: S,
        request: URLRequest,
        session: URLSession
    ) -> URLSessionDownloadTask {
        return session.downloadTask(with: request) { url, response, error in
            if let url = url, let response = response {
                _ = subscriber.receive((url, response))
                subscriber.receive(completion: .finished)
            } else if let error = error {
                subscriber.receive(completion: .failure(error))
            } else {
                assertionFailure("Expected either url: \(String(describing: url)) with response: \(String(describing: response)), or an error: \(String(describing: error))")
                subscriber.receive(completion: .finished)
            }
        }
    }
}
