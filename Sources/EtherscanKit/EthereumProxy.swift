import EthereumKit
import Foundation
import FoundationExtensions

enum EthereumProxy {
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
        let status: String
    }
}

extension EthereumProxy.Block {

    func tryDate() throws -> Date {
        let timeInterval = try Double(UInt64(hexadecimal: timestamp))
        return Date(timeIntervalSince1970: timeInterval)
    }
}

extension EthereumProxy.Transaction {

    func tryAmountInEther() throws -> Decimal {
        let amountInWei = try Decimal(UInt64(hexadecimal: value))
        return amountInWei / Ethereum.weiInEther
    }

    func tryGasPriceInEther() throws -> Decimal {
        let gasPriceInWei = try Decimal(UInt64(hexadecimal: gasPrice))
        return gasPriceInWei / Ethereum.weiInEther
    }
}

extension EthereumProxy.TransactionReceipt {

    func tryGasUsed() throws -> Decimal {
        try Decimal(UInt64(hexadecimal: gasUsed))
    }

    func tryIsSuccessful() throws -> Bool {
        try UInt64(hexadecimal: status) != 0
    }
}

extension EthereumTransaction {
    init(
        proxyBlock: EthereumProxy.Block,
        proxyTransaction: EthereumProxy.Transaction,
        proxyReceipt: EthereumProxy.TransactionReceipt
    ) throws {
        let fee = try proxyTransaction.tryGasPriceInEther() * proxyReceipt.tryGasUsed()

        try self.init(
            hash: proxyTransaction.hash,
            date: proxyBlock.tryDate(),
            from: proxyTransaction.from,
            to: proxyTransaction.to,
            amount: proxyTransaction.tryAmountInEther(),
            fee: fee,
            isSuccessful: proxyReceipt.tryIsSuccessful()
        )
    }
}

extension EthereumInternalTransaction {
    init(
        internalTransaction: Etherscan.InternalTransaction,
        proxyTransaction: EthereumProxy.Transaction,
        proxyReceipt: EthereumProxy.TransactionReceipt
    ) throws {
        let timeInterval = try Double(string: internalTransaction.timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        let fee = try proxyTransaction.tryGasPriceInEther() * proxyReceipt.tryGasUsed()

        let transaction = try EthereumTransaction(
            hash: proxyTransaction.hash,
            date: date,
            from: proxyTransaction.from,
            to: proxyTransaction.to,
            amount: proxyTransaction.tryAmountInEther(),
            fee: fee,
            isSuccessful: proxyReceipt.tryIsSuccessful()
        )

        let internalAmountInEther = try Decimal(string: internalTransaction.value) / Ethereum.weiInEther

        self.init(
            transaction: transaction,
            from: internalTransaction.from,
            to: internalTransaction.to,
            amount: internalAmountInEther
        )
    }
}
