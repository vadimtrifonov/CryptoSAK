import Combine
import Foundation
import os.log
import FoundationExtensions

public enum HTTPClientError: Error {
    case invalidRequest(baseURL: URL, path: String, parameters: [String: Any])
    case unknownError
}

public protocol HTTPClient {
    @discardableResult
    func get<T: Decodable>(
        path: String,
        parameters: [String: Any],
        handler: @escaping (Result<T>) -> Void
    ) -> URLSessionTask?

    func get<T: Decodable>(
        path: String,
        parameters: [String: Any]
    ) -> AnyPublisher<T, Error>
}

public final class DefaultHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let apiKey: String

    public init(baseURL: URL, urlSession: URLSession, apiKey: String) {
        self.baseURL = baseURL
        session = urlSession
        self.apiKey = apiKey
    }

    @discardableResult
    public func get<T: Decodable>(
        path: String,
        parameters: [String: Any],
        handler: @escaping (Result<T>) -> Void
    ) -> URLSessionTask? {
        var parameters = parameters
        parameters["apiKey"] = apiKey

        do {
            let request = try makeRequest(path: path, parameters: parameters)
            #if DEBUG
                os_log("%@", "\(request.hashValue) GET: \(path) \(parameters)")
            #endif
            return dataTask(request: request, handler: handler)
        } catch {
            handler(.failure(error))
            return nil
        }
    }

    private func dataTask<T: Decodable>(
        request: URLRequest,
        handler: @escaping (Result<T>) -> Void
    ) -> URLSessionTask {
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                #if DEBUG
                    os_log("%@", "\(request.hashValue) ERROR: \(error?.localizedDescription ?? "Unknown")")
                #endif
                return handler(.failure(error ?? HTTPClientError.unknownError))
            }

            #if DEBUG
                os_log("%@", "\(request.hashValue) RESPONSE: \(data.description)")
            #endif

            do {
                let response = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    handler(.success(response))
                }
            } catch {
                #if DEBUG
                    os_log("%@", "\(request.hashValue) DECODING FAILURE: \(String(describing: error))")
                #endif
                DispatchQueue.main.async {
                    handler(.failure(error))
                }
            }
        }

        task.resume()
        return task
    }

    private func makeRequest(path: String, parameters: [String: Any]) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.percentEncodedPath = path
        components?.percentEncodedQuery = parameters.formURLEncoded

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest(baseURL: baseURL, path: path, parameters: parameters)
        }

        return URLRequest(url: url)
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

extension DefaultHTTPClient {
    public func get<T: Decodable>(
        path: String,
        parameters: [String: Any]
    ) -> AnyPublisher<T, Error> {
        var parameters = parameters
        parameters["apiKey"] = apiKey

        do {
            let request = try makeRequest(path: path, parameters: parameters)
            #if DEBUG
                os_log("%@", "\(request.hashValue) GET: \(path) \(parameters)")
                os_log("%@", "\(request.hashValue) GET: \(request.url?.absoluteString ?? "")")
            #endif
            return executeRequest(request: request)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func executeRequest<T: Decodable>(request: URLRequest) -> AnyPublisher<T, Error> {
        return session.dataTaskPublisher(for: request).tryMap { data, _ in
            #if DEBUG
//                os_log("%@", "\(request.hashValue) RESPONSE: \(data.description)")
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
        .mapError { error in
            #if DEBUG
                os_log("%@", "\(request.hashValue) ERROR: \(error.localizedDescription)")
            #endif
            return error
        }
        .eraseToAnyPublisher()
    }
}
