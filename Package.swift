// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Session",
    platforms: [.iOS(.v13), .macOS(.v12), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "Session", targets: ["Session"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Session", dependencies: [], path: "Sources"),
        .testTarget(name: "SessionTests", dependencies: ["Session"], path: "Tests"),
    ]
)
