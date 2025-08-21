// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SherpaONNXTTS",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SherpaONNXTTS",
            targets: ["SherpaONNXTTS"]
        )
    ],
    dependencies: [
        // Depend on the RunAnywhere SDK
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "SherpaONNXTTS",
            dependencies: [
                .product(name: "RunAnywhereSDK", package: "runanywhere-swift")
            ],
            path: "Sources/SherpaONNXTTS"
        ),
        .testTarget(
            name: "SherpaONNXTTSTests",
            dependencies: ["SherpaONNXTTS"],
            path: "Tests/SherpaONNXTTSTests"
        )
    ]
)
