// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Copyright (Change Date see Readme), gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  *******
//
//  For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

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
