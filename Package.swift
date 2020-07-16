// swift-tools-version:5.1
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
                "CoinTracking",
                "DragonGlass",
                "Ethereum",
                "Etherscan",
                "FoundationExtensions",
                "Gate",
                "Hashgraph",
                "HTTPClient",
                "IDEX",
                "Lambda",
                "Tezos",
                "TezosCapital",
                "TzStats"
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
            name: "Etherscan",
            dependencies: [
                "Ethereum",
                "FoundationExtensions",
                "HTTPClient",
            ]
        ),
        .target(
            name: "DragonGlass",
            dependencies: [
                "Hashgraph",
                "FoundationExtensions",
                "HTTPClient",
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
            name: "HTTPClient",
            dependencies: []
        ),
        .target(
            name: "IDEX",
            dependencies: [
                "FoundationExtensions"
            ]
        ),
        .target(
            name: "Lambda",
            dependencies: []
        ),
        .target(
            name: "Tezos",
            dependencies: []
        ),
        .target(
            name: "TezosCapital",
            dependencies: [
                "FoundationExtensions",
                "HTTPClient"
            ]
        ),
        .target(
            name: "TzStats",
            dependencies: [
                "Tezos",
                "FoundationExtensions",
                "HTTPClient",
                "Lambda"
            ]
        ),
    ]
)
