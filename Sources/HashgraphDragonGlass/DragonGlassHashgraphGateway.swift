import Combine
import Foundation
import Hashgraph
import Networking

public struct DragonGlassHashgraphGateway: HashgraphGateway {
    private let accessKey: String
    private let urlSession: URLSession

    public init(
        accessKey: String,
        urlSession: URLSession = .shared
    ) {
        self.accessKey = accessKey
        self.urlSession = urlSession
    }

    public func fetchHashgraphTransactions(
        account: String,
        startDate: Date
    ) -> AnyPublisher<[HashgraphTransaction], Error> {
        do {
            let endpoint = try Endpoint<DragonGlass.TransactionsResponse>(
                .get,
                url: URL(string: "https://api.dragonglass.me/hedera/api/accounts/\(account)/transactions"),
                headers: ["X-API-KEY": accessKey],
                queryItems: ["consensusStartInEpoch": startDate.timeIntervalSince1970InMilliseconds] // not working, whatever the value all transactions are always returned
            )
            return urlSession
                .dataTaskPublisher(for: endpoint)
                .tryMap { response in
                    try response.data
                        .map(HashgraphTransaction.init)
                        .filter({ $0.consensusTime >= startDate })
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

private extension Date {

    var timeIntervalSince1970InMilliseconds: Int {
        Int(timeIntervalSince1970) * 1000
    }
}
