import Combine
import Commander
import Foundation
import EtherscanKit
import EthereumKit
import HTTPClient

struct CryptoSAK {
    static func run() {
        let commandGroup = Group { group in
            group.addCommand("ethereum-fees", makeFeesExporter())
            group.addCommand("ethereum-ico", makeICOExporter())
            group.addCommand("ethereum-balance", makeBalanceCalculator())
            group.addCommand("ethereum-statement", makeEthereumStatement())
            group.addCommand("ethereum-tokens-statement", makeEthereumTokensStatement())
            group.addCommand("tezos-statement", makeTezosStatement())
        }
        commandGroup.run()
    }

    private static func makeFeesExporter() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")

        return command(address) { address in
            try EthereumFeesCommand(gateway: makeEthereumGateway()).execute(address: address)
        }
    }

    private static func makeICOExporter() -> CommandType {
        let inputPath = Argument<String>("input", description: "Path to the input file")

        return command(inputPath) { inputPath in
            try EthereumICOCommand(gateway: makeEthereumGateway()).execute(inputPath: inputPath)
        }
    }

    private static func makeBalanceCalculator() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")

        return command(address) { address in
            try EthereumBalanceCommand(gateway: makeEthereumGateway()).execute(address: address)
        }
    }

    private static func makeEthereumStatement() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")
        let startDate = Option("start-date", default: Date.distantPast, description: "Oldest operation date in ISO format")

        return command(address, startDate) { address, startDate in
            try EthereumStatementCommand(gateway: makeEthereumGateway()).execute(
                address: address,
                startDate: startDate
            )
        }
    }

    private static func makeEthereumTokensStatement() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")
        let tokenListPath = Option<String>("token-list", default: "", description: "Path to CSV with whitelisted token contract addresses")
        let startDate = Option("start-date", default: Date.distantPast, description: "Oldest operation date in ISO format")

        return command(address, tokenListPath, startDate) { address, tokenListPath, startDate in
            try EthereumTokensStatementCommand(gateway: makeEthereumGateway()).execute(
                address: address,
                tokenListPath: tokenListPath,
                startDate: startDate
            )
        }
    }

    private static func makeTezosStatement() -> CommandType {
        let account = Argument<String>("account", description: "Tezos account")
        let delegateListPath = Option<String>("delegate-list", default: "", description: "Path to CSV with delegate payout accounts")
        let startDate = Option("start-date", default: Date.distantPast, description: "Oldest operation date in ISO format")

        return command(account, delegateListPath, startDate) { account, delegateListPath, startDate in
            try TezosStatementCommand().execute(
                account: account,
                delegateListPath: delegateListPath,
                startDate: startDate
            )
        }
    }
}

extension CryptoSAK {
    private static func makeEthereumGateway() throws -> EthereumGateway {
        let url: URL = "https://api.etherscan.io"
        let session = URLSession(configuration: .default)
        let httpClient = DefaultHTTPClient(baseURL: url, urlSession: session, apiKey: etherscanAPIKey)
        return EtherscanGateway(httpClient: httpClient)
    }
}
