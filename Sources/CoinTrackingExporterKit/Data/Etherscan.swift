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
        let gasPrice: String
        let gasUsed: String
        let tokenSymbol: String?
        let tokenDecimal: String?
    }
}

extension Transaction {
    
    init(transaction: Etherscan.Transaction) throws {
        let timeIntreval = try Double.make(string: transaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        var value = try Decimal.make(string: transaction.value)
        
        switch transaction.tokenDecimal {
        case let tokenDecimal? where !tokenDecimal.isEmpty:
            let decimals = try Double.make(string: tokenDecimal)
            value = value / Decimal(pow(10, decimals))
        case _?:
            break
        default:
            value = value / Transaction.weiInEther
        }
        
        let gasPriceInWei = try Decimal.make(string: transaction.gasPrice)
        let gasPriceInEther = gasPriceInWei / Transaction.weiInEther
        let gasUsed = try Decimal.make(string: transaction.gasUsed)
        let fee = gasPriceInEther * gasUsed
        
        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            value: value,
            fee: fee,
            tokenSymbol: transaction.tokenSymbol
        )
    }
}
