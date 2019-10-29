import CoinTrackingKit
import Combine
import Foundation
import HTTPClient
import LambdaKit
import TezosCapitalKit
import TezosKit
import TzStatsKit

struct TezosCapitalStatementCommand {
    static func execute(address: String, startDate: Date) throws {
        var subscriptions = Set<AnyCancellable>()

        Self.exportRewards(
            address: address,
            startDate: startDate,
            fetchRewards: Self.fetchRewards(urlSession: URLSession.shared),
            fetchCycle: Self.fetchCycle(urlSession: URLSession.shared)
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            exit(0)
        }, receiveValue: { rows in
            do {
                try write(rows: rows, filename: "TezosCapitalStatement")
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }

    static func exportRewards(
        address: String,
        startDate: Date,
        fetchRewards: (_ address: String) -> AnyPublisher<[TezosCapital.Reward], Error>,
        fetchCycle: @escaping (_ cycle: Int) -> AnyPublisher<TezosCycle, Error>
    ) -> AnyPublisher<[CoinTrackingRow], Error> {
        fetchRewards(address)
            .flatMap(maxPublishers: .max(1)) { rewards in
                fetchCycles(cycles: rewards.map({ $0.cycle }), fetchCycle: fetchCycle)
                    .map { cycles in
                        Self.filterRewardsWithCycles(
                            rewards: rewards,
                            cycles: cycles,
                            startDate: startDate
                        )
                    }
            }
            .map { rewards in
                rewards.map { reward, cycle in
                    CoinTrackingRow.makeBondPoolReward(
                        amount: reward.reward,
                        date: cycle.end
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    static func fetchRewards(
        urlSession: URLSession
    ) -> (_ address: String) -> AnyPublisher<[TezosCapital.Reward], Error> {
        { address in
            do {
                let endpoint = try TezosCapital.makeRewardsCSVEndpoint(address: address)
                return urlSession.dataTaskPublisher(for: endpoint)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
    }

    static func fetchCycle(
        urlSession: URLSession
    ) -> (_ cycle: Int) -> AnyPublisher<TezosCycle, Error> {
        { cycle in
            do {
                let endpoint = try TzStats.makeCycleEndpoint(cycle: cycle)
                return urlSession.dataTaskPublisher(for: endpoint)
                    .tryMap(TezosCycle.init(cycleInfo:))
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
    }

    static func fetchCycles(
        cycles: [Int],
        fetchCycle: (_ cycle: Int) -> AnyPublisher<TezosCycle, Error>
    ) -> AnyPublisher<[TezosCycle], Error> {
        cycles.reduce(Empty<TezosCycle, Error>().eraseToAnyPublisher()) { publisher, cycle in
            publisher.merge(with: fetchCycle(cycle)).eraseToAnyPublisher()
        }
        .collect()
        .eraseToAnyPublisher()
    }

    static func filterRewardsWithCycles(
        rewards: [TezosCapital.Reward],
        cycles: [TezosCycle],
        startDate: Date
    ) -> [(TezosCapital.Reward, TezosCycle)] {
        rewards.compactMap { reward in
            cycles.first(where: { $0.cycle == reward.cycle }).map({ (reward, $0) })
        }
        .filter({ $0.0.reward.isNormal && $0.1.end >= startDate })
    }
}

extension CoinTrackingRow {

    static func makeBondPoolReward(amount: Decimal, date: Date) -> CoinTrackingRow {
        self.init(
            type: .incoming(.mining),
            buyAmount: amount,
            buyCurrency: "XTZ",
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Tezos Capital",
            group: "Bond Pool",
            comment: "Export",
            date: date
        )
    }
}
