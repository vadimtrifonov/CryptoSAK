import Foundation

enum Ethereum {
    
    struct TransactionResponse: Decodable {
        let result: Transaction
    }
    
    struct Transaction: Decodable {
        let hash: String
        let blockNumber: String
        let from: String
        let to: String
        let value: String
        let gasPrice: String
    }
    
    struct BlockResponse: Decodable {
        let result: Block
    }
    
    struct Block: Decodable {
        let timestamp: String
    }
    
    struct TransactionReceiptResponse: Decodable {
        let result: TransactionReceipt
    }
    
    struct TransactionReceipt: Decodable {
        let gasUsed: String
    }
}

extension Transaction {
    
    init(
        block: Ethereum.Block,
        transaction: Ethereum.Transaction,
        receipt: Ethereum.TransactionReceipt
    ) throws {
        let timeIntreval = try Double(UInt64.make(hexadecimal: block.timestamp))
        let date = Date(timeIntervalSince1970: timeIntreval)
        
        let amountInWei = try Decimal(UInt64.make(hexadecimal: transaction.value))
        let amountInEther = amountInWei / Transaction.weiInEther
        
        let gasPriceInWei = try Decimal(UInt64.make(hexadecimal: transaction.gasPrice))
        let gasPriceInEther = gasPriceInWei / Transaction.weiInEther
        
        let gasUsed = try Decimal(UInt64.make(hexadecimal: receipt.gasUsed))
        let fee = gasPriceInEther * gasUsed
        
        self.init(
            hash: transaction.hash,
            date: date,
            from: transaction.from,
            to: transaction.to,
            amount: amountInEther,
            fee: fee,
            isSuccessful: true // Ethrescan proxy doesn't return a transaction receipt status
        )
    }
}
