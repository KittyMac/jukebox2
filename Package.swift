// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jukebox2",
    dependencies: [
        .package(url: "https://github.com/KittyMac/Flynn.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "jukebox2",
            dependencies: ["Flynn"]),
        .testTarget(
            name: "jukebox2Tests",
            dependencies: ["jukebox2"]),
    ]
)
