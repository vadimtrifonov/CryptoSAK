// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CryptoSAK",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "CryptoSAK",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Algorand",
                "AlgorandAlgoExplorer",
                "CoinTracking",
                "Ethereum",
                "EthereumEtherscan",
                "FoundationExtensions",
                "Gate",
                "Hashgraph",
                "HashgraphDragonGlass",
                "IDEX",
                "Kusama",
                "Lambda",
                "Networking",
                "Polkadot",
                "PolkadotSubscan",
                "Tezos",
                "TezosCapital",
                "TezosTzStats"
            ]
        ),
        .target(
            name: "Algorand",
            dependencies: []
        ),
        .target(
            name: "AlgorandAlgoExplorer",
            dependencies: [
                "Algorand",
                "FoundationExtensions",
                "Networking",
            ]
        ),
        .target(
            name: "CoinTracking",
            dependencies: []
        ),
        .target(
            name: "Ethereum",
            dependencies: []
        ),
        .target(
            name: "EthereumEtherscan",
            dependencies: [
                "Ethereum",
                "FoundationExtensions",
                "Networking",
            ]
        ),
        .target(
            name: "FoundationExtensions",
            dependencies: []
        ),
        .target(
            name: "Gate",
            dependencies: [
                "FoundationExtensions"
            ]
        ),
        .target(
            name: "Hashgraph",
            dependencies: []
        ),
        .target(
            name: "HashgraphDragonGlass",
            dependencies: [
                "Hashgraph",
                "FoundationExtensions",
                "Networking",
            ]
        ),
        .target(
            name: "IDEX",
            dependencies: [
                "FoundationExtensions"
            ]
        ),
        .target(
            name: "Kusama",
            dependencies: []
        ),
        .target(
            name: "Lambda",
            dependencies: []
        ),
        .target(
            name: "Networking",
            dependencies: []
        ),
        .target(
            name: "Polkadot",
            dependencies: []
        ),
        .target(
            name: "PolkadotSubscan",
            dependencies: [
                "FoundationExtensions",
                "Networking",
                "Polkadot",
            ]
        ),
        .target(
            name: "Tezos",
            dependencies: []
        ),
        .target(
            name: "TezosCapital",
            dependencies: [
                "FoundationExtensions",
                "Networking"
            ]
        ),
        .target(
            name: "TezosTzStats",
            dependencies: [
                "Tezos",
                "FoundationExtensions",
                "Networking",
                "Lambda"
            ]
        ),
    ]
)
