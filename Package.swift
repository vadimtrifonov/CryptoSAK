// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CryptoSAK",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "CryptoSAK",
            dependencies: [
                "Commander",
                "CoinTrackingKit",
                "EthereumKit",
                "EtherscanKit",
                "FoundationExtensions",
                "HTTPClient",
                "TezosKit",
                "TzScanKit",
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
            name: "HTTPClient",
            dependencies: []
        ),
        .testTarget(
            name: "KitTests",
            dependencies: []
        ),
        .target(
            name: "TezosKit",
            dependencies: []
        ),
        .target(
            name: "TzScanKit",
            dependencies: [
                "TezosKit",
                "FoundationExtensions",
                "HTTPClient",
            ]
        ),
    ]
)
