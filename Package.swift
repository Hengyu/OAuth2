// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OAuth2",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12),
        .tvOS(.v10)
    ],
    products: [
        .library(name: "OAuth2", targets: ["OAuth2"])
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "OAuth2", dependencies: ["Base", "Flows", "DataLoader"]),
        .target(name: "Base", dependencies: ["KeychainAccess"]),
        .target(name: "macOS", dependencies: [.target(name: "Base")]),
        .target(name: "iOS", dependencies: [.target(name: "Base")]),
        .target(name: "tvOS", dependencies: [.target(name: "Base")]),
        .target(name: "Flows", dependencies: [
            .target(name: "macOS"), .target(name: "iOS"), .target(name: "tvOS")]),
        .target(name: "DataLoader", dependencies: [.target(name: "Flows")]),
        .testTarget(name: "BaseTests", dependencies: [.target(name: "Base"), .target(name: "Flows")]),
        .testTarget(name: "FlowTests", dependencies: [.target(name: "Flows")])
    ]
)
