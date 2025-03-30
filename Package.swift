// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let isDevelop = true

let developProducts: [Product] = isDevelop ? [
    .library(
        name: "DangerDeps",
        type: .dynamic,
        targets: ["DangerDependencies"]),
] : []

let developTargets: [Target] = isDevelop ? [
    .testTarget(
        name: "DangerSwiftRemoteDangerfileTests",
        dependencies: ["DangerSwiftRemoteDangerfile"]),
    .target(
        name: "DangerDependencies",
        dependencies: ["DangerSwiftRemoteDangerfile"]),
] : []

let package = Package(
    name: "DangerSwiftRemoteDangerfile",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "DangerSwiftRemoteDangerfile",
            targets: ["DangerSwiftRemoteDangerfile"]),
    ] + developProducts,
    dependencies: [
        .package(url: "https://github.com/danger/swift.git", from: "3.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "DangerSwiftRemoteDangerfile",
            dependencies: [
                .product(name: "Danger", package: "swift"),
                .product(name: "ShellOut", package: "ShellOut"),
            ]),
    ] + developTargets
)

