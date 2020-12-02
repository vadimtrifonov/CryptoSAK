import Combine
import Foundation
import os.log

extension URLSession {

    public func dataTaskPublisher<Response>(for endpoint: Endpoint<Response>) -> AnyPublisher<Response, Error> {
        os_log("%@", "\(endpoint.request.hashValue) \(endpoint.request.httpMethod?.uppercased() ?? ""): \(endpoint.request.url?.absoluteString ?? "") \(endpoint.request.httpBody?.debugStringUTF8 ?? "")")

        return dataTaskPublisher(for: endpoint.request).tryMap { data, response in
            os_log("%@", "\(endpoint.request.hashValue) RESPONSE: \(data.debugStringUTF8)")

            return try endpoint.parseResponse(data, response)
        }
        .handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                os_log("%@", "\(endpoint.request.hashValue) ERROR: \(error.localizedDescription)")
            }
        })
        .eraseToAnyPublisher()
    }
}

private extension Data {

    var debugStringUTF8: String {
        do {
            let json = try JSONSerialization.jsonObject(with: self)
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return String(data: self, encoding: .utf8) ?? ""
        }
    }
}
