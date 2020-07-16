import ArgumentParser

struct CryptoSAK: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "CryptoSAK",
        subcommands: [
            EthereumICOStatementCommand.self,
            EthereumStatementCommand.self,
            EthereumTokensStatementCommand.self,
            GateBillingStatementCommand.self,
            HashgraphICOStatementCommand.self,
            HashgraphStatementCommand.self,
            IDEXBalanceStatementCommand.self,
            IDEXTradeStatementCommand.self,
            TezosCapitalStatementCommand.self,
            TezosStatementCommand.self,
        ]
    )
}

CryptoSAK.main()
