// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "parser-combinator-swift",
    products: [
        .library(
            name: "parser-combinator-swift",
            targets: ["parser-combinator-swift"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "parser-combinator-swift",
            dependencies: []
        ),
        .testTarget(
            name: "parser-combinator-swiftTests",
            dependencies: ["parser-combinator-swift"]
        ),
    ]
)
