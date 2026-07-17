// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RateBoi",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "RateBoi",
            targets: ["RateBoi"]),
    ],
    targets: [
        .target(
            name: "RateBoi"),
        .testTarget(
            name: "RateBoiTests",
            dependencies: ["RateBoi"]),
    ]
)
