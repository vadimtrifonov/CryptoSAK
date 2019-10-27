import Combine
import Commander
import EthereumKit
import EtherscanKit
import Foundation
import HTTPClient

struct CryptoSAK {
    static func run() {
        let commandGroup = Group { group in
            group.addCommand("ethereum-ico", makeEthereumICOStatement())
            group.addCommand("ethereum-statement", makeEthereumStatement())
            group.addCommand("ethereum-tokens-statement", makeEthereumTokensStatement())
            group.addCommand("gate-billing-statement", makeGateBillingStatement())
            group.addCommand("tezos-statement", makeTezosStatement())
            group.addCommand("tezos-capital-statement", makeTezosCapitalStatement())
        }
        commandGroup.run()
    }

    private static func makeEthereumICOStatement() -> CommandType {
        let inputPath = Argument<String>("input", description: "Path to the input file")

        return command(inputPath) { inputPath in
            try EthereumICOStatementCommand(gateway: makeEthereumGateway()).execute(inputPath: inputPath)
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

    private static func makeGateBillingStatement() -> CommandType {
        let csvPath = Argument<String>("input", description: "Path to Gate billing CSV file")

        return command(csvPath) { csvPath in
            try GateBillingStatementCommand().execute(csvPath: csvPath)
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

    private static func makeTezosCapitalStatement() -> CommandType {
        let address = Argument<String>("account", description: "Bond pool address")
        let startDate = Option("start-date", default: Date.distantPast, description: "Oldest operation date in ISO format")

        return command(address, startDate) { address, startDate in
            try TezosCapitalStatementCommand().execute(
                address: address,
                startDate: startDate
            )
        }
    }
}

extension CryptoSAK {
    private static func makeEthereumGateway() throws -> EthereumGateway {
        let url: URL = "https://api.etherscan.io"
        let session = URLSession(configuration: .default)
        let httpClient = DefaultHTTPClient(baseURL: url, urlSession: session)
        return EtherscanGateway(httpClient: httpClient)
    }
}
