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
        let tokenSymbol: String
        let tokenDecimal: String
        let txreceipt_status: String?
        let isError: String?
    }
}

extension Transaction {
    
    init(transaction: Etherscan.Transaction) throws {
        let timeIntreval = try Double.make(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        let amount = try Decimal.make(string: transaction.value) / Transaction.weiInEther
        
        var fee: Decimal = 0
        
        // Internal transactions has no gas price
        if let gasPrice = transaction.gasPrice {
            let gasPrice = try Decimal.make(string: gasPrice) / Transaction.weiInEther
            let gasUsed = try Decimal.make(string: transaction.gasUsed)
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

extension TokenTransaction {
    
    init(transaction: Etherscan.TokenTransaction) throws {
        let timeIntreval = try Double.make(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        // If token decimal is not specified assume 18 as the most common
        let decimals = !transaction.tokenDecimal.isEmpty
            ? try Double.make(string: transaction.tokenDecimal)
            : 18
        let amount = try Decimal.make(string: transaction.value) / Decimal(pow(10, decimals))
        
        let gasPrice = try Decimal.make(string: transaction.gasPrice) / Transaction.weiInEther
        let gasUsed = try Decimal.make(string: transaction.gasUsed)
        let fee = gasPrice * gasUsed
        
        let isSuccessful = transaction.isError != "1" && transaction.txreceipt_status != "0"
        
        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            amount: amount,
            fee: fee,
            contract: transaction.contractAddress,
            tokenSymbol: transaction.tokenSymbol,
            isSuccessful: isSuccessful
        )
    }
}
