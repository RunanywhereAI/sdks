import XCTest
@testable import SherpaONNXTTS
import RunAnywhereSDK

final class SherpaONNXTTSTests: XCTestCase {

    func testServiceInitialization() {
        // Test that service can be created
        let service = SherpaONNXTTSService()
        XCTAssertNotNil(service)
    }

    func testConfigurationCreation() {
        // Test configuration
        let modelPath = URL(fileURLWithPath: "/tmp/test-model")
        let config = SherpaONNXConfiguration(
            modelPath: modelPath,
            modelType: .kitten
        )

        XCTAssertEqual(config.modelPath, modelPath)
        XCTAssertEqual(config.modelType, .kitten)
        XCTAssertEqual(config.sampleRate, 16000)
        XCTAssertEqual(config.numThreads, 2)
    }

    func testModelTypes() {
        // Test all model types
        let modelTypes: [SherpaONNXModelType] = [.kitten, .kokoro, .vits, .matcha, .piper]

        for modelType in modelTypes {
            XCTAssertFalse(modelType.displayName.isEmpty)
            XCTAssertGreaterThan(modelType.estimatedMemoryUsage, 0)
        }
    }

    func testErrorDescriptions() {
        // Test error messages
        let errors: [SherpaONNXError] = [
            .notInitialized,
            .modelNotFound("test-model"),
            .voiceNotFound("test-voice"),
            .synthesisFailure("test failure"),
            .invalidConfiguration("bad config"),
            .frameworkNotLoaded,
            .unsupportedModelType("unknown")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testModelManager() {
        let sdk = RunAnywhereSDK.shared
        let manager = SherpaONNXModelManager(sdk: sdk)

        // Test model registration
        manager.registerModels()

        // Test model retrieval
        let kittenModel = manager.getModel(by: "sherpa-kitten-nano-v0.1")
        XCTAssertNotNil(kittenModel)
        XCTAssertEqual(kittenModel?.id, "sherpa-kitten-nano-v0.1")

        // Test optimal model selection
        let optimalModel = manager.selectOptimalModel()
        XCTAssertEqual(optimalModel, "sherpa-kitten-nano-v0.1")
    }

    // MARK: - Async Tests

    func testServiceInitializationAsync() async throws {
        // This test would require XCFrameworks to be built
        // For now, we just test that the service can be created
        let service = SherpaONNXTTSService()
        XCTAssertNotNil(service)

        // Initialization would fail without frameworks
        // So we don't call initialize() in this test
    }
}
