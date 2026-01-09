// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SecureBankKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SecureBankKit",
            targets: ["SecureBankKit"]
        ),
    ],
    targets: [
        .target(
            name: "SecureBankKit"
        ),
        .testTarget(
            name: "SecureBankKitTests",
            dependencies: ["SecureBankKit"]
        ),
    ]
)
