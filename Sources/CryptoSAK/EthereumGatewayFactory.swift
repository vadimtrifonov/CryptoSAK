import Ethereum
import Etherscan
import Foundation
import FoundationExtensions
import Networking

func makeEthereumGateway() -> EthereumGateway {
    let url: URL = "https://api.etherscan.io"
    let session = URLSession(configuration: .default)
    let httpClient = DefaultHTTPClient(baseURL: url, urlSession: session)
    return EtherscanGateway(httpClient: httpClient, apiKey: Config.etherscanAPIKey)
}
