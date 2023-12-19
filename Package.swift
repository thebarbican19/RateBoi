// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RateBoi",
    platforms: [
            .macOS(.v13),  // macOS 10.13 (High Sierra)
            .iOS(.v13),      // iOS 11 (Equivalent to macOS 10.13 release year)
            .watchOS(.v4),   // watchOS 4 (Equivalent to macOS 10.13 release year)
            .tvOS(.v13)      // tvOS 11 (Equivalent to macOS 10.13 release year)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RateBoi",
            targets: ["RateBoi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/thebarbican19/EnalogSwift", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RateBoi"),
        .testTarget(
            name: "RateBoiTests",
            dependencies: ["RateBoi"]),
    ]
)
