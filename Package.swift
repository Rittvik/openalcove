// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenAlcove",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenAlcove", targets: ["OpenAlcove"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OpenAlcove",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
