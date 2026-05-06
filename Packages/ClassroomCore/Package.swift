// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClassroomCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "ClassroomTheory", targets: ["ClassroomTheory"]),
        .library(name: "MusicRendering", targets: ["MusicRendering"]),
        .library(name: "AudioInput", targets: ["AudioInput"]),
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    dependencies: [
        // MusicCore is the shared package (github.com/e7mac/MusicCore).
        // Path-pinned so editing across the two repos doesn't require
        // a tag bump while the integration is in flux.
        .package(path: "../../../MusicCore"),
    ],
    targets: [
        .target(
            name: "ClassroomTheory",
            dependencies: [
                .product(name: "MusicTheory", package: "MusicCore"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MusicRendering",
            dependencies: ["ClassroomTheory"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "AudioInput",
            dependencies: [
                "ClassroomTheory",
                .product(name: "AudioEngine", package: "MusicCore"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "AppCore",
            dependencies: ["ClassroomTheory", "MusicRendering", "AudioInput"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ClassroomTheoryTests",
            dependencies: ["ClassroomTheory"]
        ),
        .testTarget(
            name: "MusicRenderingTests",
            dependencies: ["MusicRendering"]
        ),
        .testTarget(
            name: "AudioInputTests",
            dependencies: ["AudioInput"]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"]
        ),
    ]
)
