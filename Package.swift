// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jukebox2",
    dependencies: [
        .package(url: "https://github.com/KittyMac/Flynn.git", .branch("master")),
		.package(name: "portaudio", url: "https://github.com/KittyMac/portaudio-swift.git", .branch("master")),
		.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.2.0"))
    ],
    targets: [
        .target(
            name: "jukebox2",
            dependencies: [
				"Flynn",
				"portaudio",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]),
        .testTarget(
            name: "jukebox2Tests",
            dependencies: ["jukebox2"]),
    ]
)
