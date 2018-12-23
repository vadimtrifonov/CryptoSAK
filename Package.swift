// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoinTrackingExporter",
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0")
    ],
    targets: [
        .target(
            name: "CoinTrackingExporter",
            dependencies: ["Commander", "CoinTrackingExporterKit"]),
        .target(
            name: "CoinTrackingExporterKit",
            dependencies: []),
        .testTarget(
            name: "CoinTrackingExporterKitTests",
            dependencies: ["CoinTrackingExporterKit"]),
    ]
)
