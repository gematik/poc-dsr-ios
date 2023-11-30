// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceSecurityRatingApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "DeviceSecurityRatingApp",
            targets: ["DeviceSecurityRatingApp"]
        ),
    ],
    dependencies: [
        .package(name: "DeviceSecurityRating", path: "../../"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            .upToNextMajor(from: "1.1.0")
        ),
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "DeviceSecurityRatingApp",
            dependencies: [
                .product(name: "DeviceSecurityRating", package: "DeviceSecurityRating"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            resources: [
                .process("Resources/"),
            ]
        ),
        .testTarget(
            name: "DeviceSecurityRatingAppTests",
            dependencies: ["DeviceSecurityRatingApp"]
        ),
    ]
)
