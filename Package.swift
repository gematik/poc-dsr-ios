// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceSecurityRating",
    platforms: [
        .iOS(.v15),
        .macOS(.v12) // uncomment for openapi generator plugin
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DeviceSecurityRating",
            targets: ["DeviceSecurityRating"]
        ),
        .library(
            name: "OpenAPIClientInit",
            targets: ["OpenAPIClientInit"]
        ),
        .library(
            name: "OpenAPIClientAttest",
            targets: ["OpenAPIClientAttest"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gematik/ASN1Kit.git", branch: "1.2.0"),
        .package(url: "https://github.com/gematik/OpenSSL-Swift.git", from: "4.1.0"),
        .package(url: "https://github.com/SwiftCommon/DataKit.git", from: "1.1.0"),
                // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DeviceSecurityRating",
            dependencies: [
                .product(name: "ASN1Kit", package: "ASN1Kit"),
                .product(name: "OpenSSL-Swift", package: "OpenSSL-Swift"),
                .product(name: "DataKit", package: "DataKit"),
                .target(name: "OpenAPIClientInit"),
                .target(name: "OpenAPIClientAttest"),
            ],
            resources: [
                .process("Resources/")
            ]
        ),
        .target(
            name: "OpenAPIClientInit",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ]
        ),
        .target(
            name: "OpenAPIClientAttest",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ]
        ),
        .testTarget(
            name: "DeviceSecurityRatingTests",
            dependencies: ["DeviceSecurityRating"]),
    ]
)
