// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DangerRemoteImport",
    products: [
        .library(
            name: "DangerRemoteImport",
            targets: ["DangerRemoteImport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danger/swift.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "DangerRemoteImport",
            dependencies: [
                .product(name: "Danger", package: "swift")
            ]
        ),
//        .testTarget(
//            name: "DangerRemoteImportTests",
//            dependencies: ["DangerRemoteImport"]
//        ),
    ]
)
