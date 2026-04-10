// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarkdownReader",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ReaderCore",
            targets: ["ReaderCore"]
        ),
        .executable(
            name: "MarkdownReader",
            targets: ["MarkdownReader"]
        )
    ],
    targets: [
        .target(
            name: "ReaderCore"
        ),
        .executableTarget(
            name: "MarkdownReader",
            dependencies: ["ReaderCore"]
        ),
        .testTarget(
            name: "ReaderCoreTests",
            dependencies: ["ReaderCore"],
            path: "Tests/ReaderCoreTests"
        )
    ]
)
