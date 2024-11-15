// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Whispering",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Whispering",
            dependencies: ["WhisperKit"],
            path: "Sources"
        )
    ]
)
