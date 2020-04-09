import ArgumentParser

struct CryptoSAK: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "CryptoSAK",
        subcommands: [
            EthereumICOStatementCommand.self,
            EthereumStatementCommand.self,
            EthereumTokensStatementCommand.self,
            IDEXBalanceStatementCommand.self,
            IDEXTradeStatementCommand.self,
            GateBillingStatementCommand.self,
            TezosCapitalStatementCommand.self,
            TezosStatementCommand.self,
        ]
    )
}

CryptoSAK.main()
