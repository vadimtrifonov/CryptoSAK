import ArgumentParser

struct CryptoSAK: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "CryptoSAK",
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
