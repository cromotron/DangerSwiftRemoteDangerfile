// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DangerSwiftRemoteDangerfile",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "DangerSwiftRemoteDangerfile", targets: ["DangerSwiftRemoteDangerfile"]),
        .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"]) // dev
    ],
    dependencies: [
            .package(url: "https://github.com/danger/swift.git", from: "3.0.0"),
            .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0"),
            .package(url: "https://github.com/f-meloni/Rocket", from: "1.0.0"), // dev,
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "DangerDependencies", dependencies: [.product(name: "Danger", package: "swift"), "DangerSwiftRemoteDangerfile"]), // dev
        .target(
            name: "DangerSwiftRemoteDangerfile",
            dependencies: [
                .product(name: "Danger", package: "swift"),
                .product(name: "ShellOut", package: "ShellOut"),
            ]
        ),
        .testTarget(
            name: "DangerSwiftRemoteDangerfileTests",
            dependencies: ["DangerSwiftRemoteDangerfile"]
        ),
    ]
)
