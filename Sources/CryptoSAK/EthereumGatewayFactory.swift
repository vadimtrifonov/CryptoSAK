import EthereumKit
import EtherscanKit
import Foundation
import FoundationExtensions
import HTTPClient

func makeEthereumGateway() -> EthereumGateway {
    let url: URL = "https://api.etherscan.io"
    let session = URLSession(configuration: .default)
    let httpClient = DefaultHTTPClient(baseURL: url, urlSession: session)
    return EtherscanGateway(httpClient: httpClient, apiKey: Config.etherscanAPIKey)
}
