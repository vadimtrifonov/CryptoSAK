import Commander
import Foundation
import CoinTrackingExporterKit

struct CoinTrackingExporter {
    
    static func run() {
        let commandGroup = Group { group in
            group.addCommand("ether-transaction-fees", makeCommand())
        }
        commandGroup.run()
    }
    
    private static func makeCommand() -> CommandType {
        let address = Argument<String>("address", description: "Etherium address")
        
        return command(address) { address in
            var shouldKeepRunning = true
            
            let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let apiKey = try etherscanAPIKey(rootDirectory: outputDirectory)
            let url: URL = "https://api.etherscan.io"
            
            let session = URLSession(configuration: .default)
            let apiClient = APIClientImpl(baseURL: url, urlSession: session, apiKey: apiKey)
            let gateway = EtherscanGatewayImpl(apiClient: apiClient)
            let exporter = EtherTransactionFeesExporterImpl(etherscanGateway: gateway)
            
            exporter.export(address: address) { result in
                do {
                    let coinTrackingRows = try result.unwrap()
                    let coinTrackingCSV = CoinTrackingRow.makeCSV(rows: coinTrackingRows)
                    
                    let coinTrackingURL = outputDirectory.appendingPathComponent("CoinTracking.csv")
                    try coinTrackingCSV.write(to: coinTrackingURL, atomically: true, encoding: .ascii)
                    
                    print("Done, wrote \(coinTrackingRows.count) rows to \(coinTrackingURL.path)")
                } catch {
                    print(error.localizedDescription)
                }
                
                shouldKeepRunning = false
            }
            
            while shouldKeepRunning && RunLoop.current.run(mode: .default, before: Date.distantFuture) {}
        }
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
}

extension URL: ExpressibleByStringLiteral {
    public typealias StringLiteralType = StaticString
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value.description)!
    }
}
