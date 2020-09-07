import Foundation
import ArgumentParser

struct BlockstackICOCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "idex-trade-statement")

    var address:
    
    @Argument(help: "Path to CSV file with Blockstack ICO payouts")
    var csvPath: String

    func run() throws {
        let csvRows = try File.read(path: csvPath).dropFirst() // drop header row
        let tradeRows = try csvRows.map(IDEXTradeRow.init)
        let rows = tradeRows.map(CoinTrackingRow.init)
        try File.write(rows: rows, filename: "IDEXTradeStatement")
    }
}
