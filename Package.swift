// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Session",
    platforms: [.iOS(.v18), .macOS(.v15), .watchOS(.v11), .tvOS(.v18)],
    products: [
        .library(name: "Session", targets: ["Session"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JARMourato/RNP.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(name: "Session", dependencies: ["RNP"], path: "Sources"),
        .testTarget(name: "SessionTests", dependencies: ["RNP", "Session"], path: "Tests"),
    ]
)
