import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Lambda
import Networking
import Tezos
import TezosCapital
import TezosTzStats

struct TezosCapitalStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "tezos-capital-statement",
        abstract: "Export Tezos Capital staking rewards",
        shouldDisplay: false
    )

    @Argument(help: "Bond pool address")
    var address: String

    @Option(help: .startDate(eventsName: "operations"))
    var startDate: Date = .distantPast

    func run() throws {
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
            Self.exit()
        }, receiveValue: { rows in
            do {
                try FileManager.default.writeCSV(rows: rows, filename: "TezosCapitalStatement")
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
                recursivelyFetchRewardCycles(
                    rewardsIterator: rewards.makeSortedIterator(),
                    accumulatedRewardsWithCycles: [],
                    startDate: startDate,
                    fetchCycle: fetchCycle
                )
            }
            .map { rewardsWithCycles in
                rewardsWithCycles.map(CoinTrackingRow.makeBondPoolReward)
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

    static func recursivelyFetchRewardCycles(
        rewardsIterator: IndexingIterator<[TezosCapital.Reward]>,
        accumulatedRewardsWithCycles: [(TezosCapital.Reward, TezosCycle)],
        startDate: Date,
        fetchCycle: @escaping (_ cycle: Int) -> AnyPublisher<TezosCycle, Error>
    ) -> AnyPublisher<[(TezosCapital.Reward, TezosCycle)], Error> {
        var rewardsIterator = rewardsIterator
        guard let reward = rewardsIterator.next() else {
            return Just(accumulatedRewardsWithCycles).mapError(toError).eraseToAnyPublisher()
        }

        return fetchCycle(reward.cycle)
            .map { cycle in
                accumulateRewardsWithCycles(
                    reward: reward,
                    cycle: cycle,
                    accumulatedRewardsWithCycles: accumulatedRewardsWithCycles,
                    startDate: startDate
                )
            }
            .flatMap(maxPublishers: .max(1)) { accumulatedRewardsWithCycles, startDateReached -> AnyPublisher<[(TezosCapital.Reward, TezosCycle)], Error> in
                if startDateReached {
                    return Just(accumulatedRewardsWithCycles).mapError(toError).eraseToAnyPublisher()
                }

                return recursivelyFetchRewardCycles(
                    rewardsIterator: rewardsIterator,
                    accumulatedRewardsWithCycles: accumulatedRewardsWithCycles,
                    startDate: startDate,
                    fetchCycle: fetchCycle
                )
            }
            .eraseToAnyPublisher()
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

    static func accumulateRewardsWithCycles(
        reward: TezosCapital.Reward,
        cycle: TezosCycle,
        accumulatedRewardsWithCycles: [(TezosCapital.Reward, TezosCycle)],
        startDate: Date
    ) -> ([(TezosCapital.Reward, TezosCycle)], startDateReached: Bool) {
        var accumulatedRewardsWithCycles = accumulatedRewardsWithCycles
        let startDateReached = cycle.end < startDate

        if reward.reward.isNormal, !startDateReached {
            accumulatedRewardsWithCycles.append((reward, cycle))
        }

        return (accumulatedRewardsWithCycles, startDateReached: startDateReached)
    }
}

extension Array where Element == TezosCapital.Reward {
    func makeSortedIterator() -> IndexingIterator<[TezosCapital.Reward]> {
        sorted(by: { $0.cycle > $1.cycle }).makeIterator()
    }
}

extension CoinTrackingRow {

    static func makeBondPoolReward(reward: TezosCapital.Reward, cycle: TezosCycle) -> CoinTrackingRow {
        self.init(
            type: .incoming(.staking),
            buyAmount: reward.reward,
            buyCurrency: Tezos.ticker,
            sellAmount: 0,
            sellCurrency: "",
            fee: 0,
            feeCurrency: "",
            exchange: "Tezos Capital",
            group: "Bond Pool",
            comment: Self.makeComment("Cycle: \(cycle.cycle)"),
            date: cycle.end
        )
    }
}
