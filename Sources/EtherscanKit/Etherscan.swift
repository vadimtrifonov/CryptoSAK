import EthereumKit
import Foundation

enum Etherscan {
    struct TransactionsResponse: Decodable {
        let status: String
        let message: String
        let result: [Transaction]
    }

    struct Transaction: Decodable {
        let hash: String
        let timeStamp: String
        let from: String
        let to: String
        let value: String
        let gasUsed: String
        let gasPrice: String?
        let txreceipt_status: String?
        let isError: String?
    }

    struct TokenTransactionsResponse: Decodable {
        let status: String
        let message: String
        let result: [TokenTransaction]
    }

    struct TokenTransaction: Decodable {
        let hash: String
        let timeStamp: String
        let from: String
        let to: String
        let value: String
        let gasPrice: String
        let gasUsed: String
        let contractAddress: String
        let tokenName: String
        let tokenSymbol: String
        let tokenDecimal: String
        let txreceipt_status: String?
        let isError: String?
    }

    struct InternalTransactionByHashResponse: Decodable {
        let status: String
        let message: String
        let result: [InternalTransaction]
    }

    struct InternalTransaction: Decodable {
        let blockNumber: String
        let timeStamp: String
        let from: String
        let to: String
        let value: String
        let isError: String?
    }
}

extension EthereumTransaction {
    init(transaction: Etherscan.Transaction) throws {
        let timeIntreval = try Double(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)

        let amount = try Decimal(string: transaction.value) / Ethereum.weiInEther

        var fee: Decimal = 0

        // Internal transactions has no gas price
        if let gasPrice = transaction.gasPrice {
            let gasPrice = try Decimal(string: gasPrice) / Ethereum.weiInEther
            let gasUsed = try Decimal(string: transaction.gasUsed)
            fee = gasPrice * gasUsed
        }

        let isSuccessful = transaction.isError != "1" && transaction.txreceipt_status != "0"

        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            amount: amount,
            fee: fee,
            isSuccessful: isSuccessful
        )
    }
}

extension EthereumTokenTransaction {
    init(transaction: Etherscan.TokenTransaction) throws {
        let timeIntreval = try Double(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)

        let decimalPlaces = try Int(string: transaction.tokenDecimal)
        let amount = try Decimal(string: transaction.value) / pow(10, decimalPlaces)

        let gasPrice = try Decimal(string: transaction.gasPrice) / Ethereum.weiInEther
        let gasUsed = try Decimal(string: transaction.gasUsed)
        let fee = gasPrice * gasUsed

        let isSuccessful = transaction.isError != "1" && transaction.txreceipt_status != "0"

        let token = EthereumToken(
            contractAddress: transaction.contractAddress,
            name: transaction.tokenName,
            symbol: transaction.tokenSymbol,
            decimalPlaces: decimalPlaces
        )

        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            amount: amount,
            fee: fee,
            token: token,
            isSuccessful: isSuccessful
        )
    }
}
