import Commander
import Foundation
import CoinTrackingExporterKit

struct CoinTrackingExporter {
    
    static func run() {
        let commandGroup = Group { group in
            group.addCommand("ethereum-fees", makeFeesExporter())
            group.addCommand("ethereum-ico", makeICOExporter())
        }
        commandGroup.run()
    }
    
    private static func makeFeesExporter() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")
        
        return command(address) { address in
            var shouldKeepRunning = true
            
            let rootDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let gateway = try makeEtherscanGateway(rootDirectory: rootDirectory)
            let exporter = EthereumFeesExporterImpl(etherscanGateway: gateway)
            
            exporter.export(address: address) { result in
                write(result: result, to: rootDirectory)
                shouldKeepRunning = false
            }
            
            while shouldKeepRunning && RunLoop.current.run(mode: .default, before: .distantFuture) {}
        }
    }
    
    private static func makeICOExporter() -> CommandType {
        let inputPath = Argument<String>("input", description: "Path to the input file")
        
        return command(inputPath) { inputPath in
            var shouldKeepRunning = true
            
            let rootDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let gateway = try makeEtherscanGateway(rootDirectory: rootDirectory)
            let exporter = EthereumICOExporterImpl(etherscanGateway: gateway)
            
            let url = URL(fileURLWithPath: inputPath)
            let csv = try String(contentsOf: url)
            let csvRows = csv.components(separatedBy: .newlines).filter({ !$0.isEmpty })
            
            guard let ico = try csvRows.map(ICO.init).first else {
                print("Nothing to export")
                shouldKeepRunning = false
                return
            }
            
            exporter.export(ico: ico) { result in
                write(result: result, to: rootDirectory)
                shouldKeepRunning = false
            }
            
            while shouldKeepRunning && RunLoop.current.run(mode: .default, before: .distantFuture) {}
        }
    }
    
    private static func makeEtherscanGateway(rootDirectory: URL) throws -> EtherscanGateway {
        let apiKey = try etherscanAPIKey(rootDirectory: rootDirectory)
        let url: URL = "https://api.etherscan.io"
    
        let session = URLSession(configuration: .default)
        let apiClient = APIClientImpl(baseURL: url, urlSession: session, apiKey: apiKey)
        return EtherscanGatewayImpl(apiClient: apiClient)
    }
    
    private static func etherscanAPIKey(rootDirectory: URL) throws -> String {
        let url = rootDirectory.appendingPathComponent("Configuration.plist")
        
        guard let configuration = NSDictionary(contentsOf: url) as? [String: String] else {
            throw "Failed to read configuration: \(url)"
        }
        guard let apiKey = configuration["EtherscanAPIKey"], !apiKey.isEmpty else {
            throw "Etherscan API key cannot found: \(url)"
        }
        
        return apiKey
    }
    
    private static func write(result: Result<[CoinTrackingRow]>, to directory: URL) {
        do {
            let coinTrackingRows = try result.unwrap()
            let coinTrackingCSV = CoinTrackingRow.makeCSV(rows: coinTrackingRows)
            
            let coinTrackingURL = directory.appendingPathComponent("CoinTracking.csv")
            try coinTrackingCSV.write(to: coinTrackingURL, atomically: true, encoding: .ascii)
            
            print("Done, wrote \(coinTrackingRows.count) rows to \(coinTrackingURL.path)")
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension URL: ExpressibleByStringLiteral {
    public typealias StringLiteralType = StaticString
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value.description)!
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
