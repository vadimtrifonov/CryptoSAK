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
        let gasPrice: String?
        let gasUsed: String
        let tokenSymbol: String?
        let tokenDecimal: String?
        let txreceipt_status: String?
        let isError: String?
    }
}

extension Transaction {
    
    init(transaction: Etherscan.Transaction) throws {
        let timeIntreval = try Double.make(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        var amount = try Decimal.make(string: transaction.value)
        
        switch transaction.tokenDecimal {
        // Token transaction
        case let tokenDecimal? where !tokenDecimal.isEmpty:
            let decimals = try Double.make(string: tokenDecimal)
            amount = amount / Decimal(pow(10, decimals))
        // Token transaction with unknown decimals
        case _?:
            break
        // Normal transaction
        default:
            amount = amount / Transaction.weiInEther
        }
        
        var fee: Decimal = 0
        
        // Internal transactions has no gas price
        if let gasPrice = transaction.gasPrice {
            let gasPriceInWei = try Decimal.make(string: gasPrice)
            let gasPriceInEther = gasPriceInWei / Transaction.weiInEther
            let gasUsed = try Decimal.make(string: transaction.gasUsed)
            fee = gasPriceInEther * gasUsed
        }
        
        let isSuccessful = transaction.isError != "1" && transaction.txreceipt_status != "0"
        
        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            amount: amount,
            fee: fee,
            tokenSymbol: transaction.tokenSymbol,
            isSuccessful: isSuccessful
        )
    }
}
