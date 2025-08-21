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
                .product(name: "RunAnywhereSDK", package: "runanywhere-swift"),
                "SherpaONNXFramework",
                "ONNXRuntimeFramework"
            ],
            path: "Sources/SherpaONNXTTS",
            publicHeadersPath: "Internal/Bridge",
            cxxSettings: [
                .headerSearchPath("Internal/Bridge"),
                .define("SHERPA_ONNX_AVAILABLE", .when(platforms: [.iOS, .macOS]))
            ]
        ),
        // Binary targets for XCFrameworks
        .binaryTarget(
            name: "SherpaONNXFramework",
            path: "XCFrameworks/sherpa-onnx.xcframework"
        ),
        .binaryTarget(
            name: "ONNXRuntimeFramework",
            path: "XCFrameworks/onnxruntime.xcframework"
        ),
        .testTarget(
            name: "SherpaONNXTTSTests",
            dependencies: ["SherpaONNXTTS"],
            path: "Tests/SherpaONNXTTSTests"
        )
    ]
)
