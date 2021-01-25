import ArgumentParser

struct CryptoSAK: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "CryptoSAK",
        abstract: "Crypto SAK is a tool for exporting cryptocurrency transactions to CoinTracking (https://cointracking.info) format",
        discussion: "DISCLAIMER: The tool is not tested beyond my own personal use. No correctness guarantees are given. Service APIs might change and the tool will no longer be able to export transactions.",
        subcommands: [
            AlgorandStatementCommand.self,
            BlockstackICOStatementCommand.self,
            EthereumICOStatementCommand.self,
            EthereumStatementCommand.self,
            EthereumTokensStatementCommand.self,
            GateBillingStatementCommand.self,
            HashgraphICOStatementCommand.self,
            HashgraphStatementCommand.self,
            IDEXBalanceStatementCommand.self,
            IDEXTradeStatementCommand.self,
            KusamaExtrinsicsStatementCommand.self,
            KusamaRewardsStatementCommand.self,
            PolkadotExtrinsicsStatementCommand.self,
            PolkadotRewardsStatementCommand.self,
            TezosCapitalStatementCommand.self,
            TezosStatementCommand.self,
        ]
    )
}

CryptoSAK.main()
