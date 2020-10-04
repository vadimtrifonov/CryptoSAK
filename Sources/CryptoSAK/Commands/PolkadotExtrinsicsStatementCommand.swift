import ArgumentParser
import CoinTracking
import Combine
import Foundation
import Polkadot
import PolkadotSubscan

struct PolkadotExtrinsicsStatementCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "polkadot-extrinsics-statement")

    @Argument(help: "Polkadot address")
    var address: String

    @Option(default: Date.distantPast, help: "Oldest date from which extrinsics will be exported")
    var startDate: Date

    func run() throws {
        var subscriptions = Set<AnyCancellable>()

        Self.exportExtrinsicsStatement(
            address: address,
            fetchExtrinsics: SubscanPolkadotGateway().fetchExtrinsics,
            startDate: startDate
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print(error)
            }
            Self.exit()
        }, receiveValue: { statement in
            do {
                try FileManager.default.writeCSV(
                    rows: statement.toCoinTrackingRows(),
                    filename: "PolkadotRewardsStatement"
                )
            } catch {
                print(error)
            }
        })
        .store(in: &subscriptions)

        RunLoop.main.run()
    }
}

extension PolkadotExtrinsicsStatementCommand {

    static func exportExtrinsicsStatement(
        address: String,
        fetchExtrinsics: (String, Date) -> AnyPublisher<[PolkadotExtrinsic], Error>,
        startDate: Date
    ) -> AnyPublisher<PolkadotExtrinsicsStatement, Error> {
        fetchExtrinsics(address, startDate)
            .map(PolkadotExtrinsicsStatement.init)
            .eraseToAnyPublisher()
    }
}

extension PolkadotExtrinsicsStatement {
    
    func toCoinTrackingRows() -> [CoinTrackingRow] {
        []
    }
}
