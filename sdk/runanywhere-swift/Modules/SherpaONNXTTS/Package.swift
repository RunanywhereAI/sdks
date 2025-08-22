// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SherpaONNXTTS",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
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
                "SherpaONNXBridge"
            ],
            path: "Sources/SherpaONNXTTS"
        ),
        .target(
            name: "SherpaONNXBridge",
            dependencies: [
                "SherpaONNXFramework",
                "ONNXRuntimeFramework"
            ],
            path: "Sources/SherpaONNXBridge",
            publicHeadersPath: ".",
            cxxSettings: [
                .define("SHERPA_ONNX_AVAILABLE", .when(platforms: [.iOS, .macOS])),
                .headerSearchPath("../../XCFrameworks/sherpa-onnx.xcframework/Headers"),
                .headerSearchPath("../../XCFrameworks/onnxruntime.xcframework/Headers")
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
