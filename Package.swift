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
                "CoinTrackingKit",
                "EthereumKit",
                "EtherscanKit",
                "FoundationExtensions",
                "GateKit",
                "HTTPClient",
                "IDEXKit",
                "LambdaKit",
                "TezosKit",
                "TezosCapitalKit",
                "TzStatsKit"
            ]
        ),
        .target(
            name: "CoinTrackingKit",
            dependencies: []
        ),
        .target(
            name: "EthereumKit",
            dependencies: []
        ),
        .target(
            name: "EtherscanKit",
            dependencies: [
                "EthereumKit",
                "FoundationExtensions",
                "HTTPClient",
            ]
        ),
        .target(
            name: "FoundationExtensions",
            dependencies: []
        ),
        .target(
            name: "GateKit",
            dependencies: [
                "FoundationExtensions"
            ]
        ),
        .target(
            name: "HTTPClient",
            dependencies: []
        ),
        .target(
            name: "IDEXKit",
            dependencies: [
                "FoundationExtensions"
            ]
        ),
        .testTarget(
            name: "KitTests",
            dependencies: []
        ),
        .target(
            name: "LambdaKit",
            dependencies: []
        ),
        .target(
            name: "TezosKit",
            dependencies: []
        ),
        .target(
            name: "TezosCapitalKit",
            dependencies: [
                "FoundationExtensions",
                "HTTPClient"
            ]
        ),
        .target(
            name: "TzStatsKit",
            dependencies: [
                "TezosKit",
                "FoundationExtensions",
                "HTTPClient",
                "LambdaKit"
            ]
        ),
    ]
)
