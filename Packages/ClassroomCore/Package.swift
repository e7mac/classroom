// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClassroomCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MusicTheory", targets: ["MusicTheory"]),
        .library(name: "MusicRendering", targets: ["MusicRendering"]),
        .library(name: "AudioInput", targets: ["AudioInput"]),
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    targets: [
        .target(
            name: "MusicTheory",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MusicRendering",
            dependencies: ["MusicTheory"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "AudioInput",
            dependencies: ["MusicTheory"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "AppCore",
            dependencies: ["MusicTheory", "MusicRendering", "AudioInput"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MusicTheoryTests",
            dependencies: ["MusicTheory"]
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
