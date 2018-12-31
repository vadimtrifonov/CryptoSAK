import Foundation

public enum APIClientError: Error {
    case invalidRequest(baseURL: URL, path: String, parameters: [String: Any])
    case unknownError
}

public protocol APIClient {
    
    @discardableResult
    func get<T: Decodable>(
        path: String,
        parameters: [String: Any],
        handler: @escaping (Result<T>) -> Void
    ) -> URLSessionTask?
}

public final class APIClientImpl: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let apiKey: String
    
    public init(baseURL: URL, urlSession: URLSession, apiKey: String) {
        self.baseURL = baseURL
        self.session = urlSession
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
                NSLog("%@", "\(request.hashValue) GET: \(path) \(parameters)")
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
    ) -> URLSessionTask  {
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                #if DEBUG
                    NSLog("%@", "\(request.hashValue) ERROR: \(error?.localizedDescription ?? "Unknown")")
                #endif
                return handler(.failure(error ?? APIClientError.unknownError))
            }
            
            #if DEBUG
                NSLog("%@", "\(request.hashValue) RESPONSE: \(data.description)")
            #endif
            
            do {
                let response = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    handler(.success(response))
                }
            } catch {
                #if DEBUG
                    NSLog("%@", "\(request.hashValue) DECODING FAILURE: \(error.localizedDescription)")
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
            throw APIClientError.invalidRequest(baseURL: baseURL, path: path, parameters: parameters)
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

