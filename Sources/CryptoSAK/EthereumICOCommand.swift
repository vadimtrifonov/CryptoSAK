import Foundation
import EtherscanKit
import EthereumKit

struct EthereumICOCommand {
    let gateway: EthereumGateway
    
    func execute(inputPath: String) throws {
        let exporter = DefaultEthereumICOExporter(etherscanGateway: gateway)

        let csvRows = try CSV.read(path: inputPath)

        guard let ico = try csvRows.map(ICO.init).first else {
            print("Nothing to export")
            exit(1)
        }

        exporter.export(ico: ico) { result in
            do {
                try write(rows: result.unwrap(), filename: String(describing: self))
            } catch {
                print(error)
            }
            exit(0)
        }

        RunLoop.main.run()
    }
}

extension ICO {
    init(csvRow: String) throws {
        let columns = csvRow.split(separator: ",").map(String.init)

        let minimumColumns = 3
        guard columns.count >= minimumColumns else {
            throw "Expected at least \(minimumColumns) columns, got \(columns)"
        }

        self.init(
            name: columns[0],
            tokenSymbol: columns[1],
            contributionHashes: Array(columns.dropFirst(2))
        )
    }
}

// extension CoinTrackingRow {
//
//    static func makeDeposit(ico: ICO, transaction: EthereumTransaction) -> CoinTrackingRow {
//        return CoinTrackingRow(
//            type: .incoming(.deposit),
//            buyAmount: transaction.amount,
//            buyCurrency: "ETH",
//            sellAmount: 0,
//            sellCurrency: "",
//            fee: 0,
//            feeCurrency: "",
//            exchange: ico.name,
//            group: "",
//            comment: "Export \(transaction.hash)",
//            date: transaction.date
//        )
//    }
// }
