import Foundation
import RunAnywhereSDK
import os

/// Manages Sherpa-ONNX TTS models registration with SDK
final class SherpaONNXModelManager {

    private let sdk: RunAnywhereSDK
    private let logger = Logger(
        subsystem: "com.runanywhere.sdk",
        category: "SherpaONNXModelManager"
    )

    init(sdk: RunAnywhereSDK) {
        self.sdk = sdk
    }

    /// Register all available Sherpa-ONNX models with the SDK
    func registerModels() {
        let models = createModelDefinitions()
        sdk.registerModuleModels(models)
        logger.info("Registered \(models.count) Sherpa-ONNX models")
    }

    private func createModelDefinitions() -> [ModelInfo] {
        return [
            // Kitten TTS - Smallest, fastest model
            ModelInfo(
                id: "sherpa-kitten-nano-v0.1",
                name: "Kitten TTS Nano",
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/model.onnx"),
                estimatedMemory: 50_000_000,
                downloadSize: 25_000_000,
                metadata: ModelInfoMetadata(
                    tags: ["tts", "sherpa-onnx", "lightweight"],
                    description: "Lightweight neural TTS with 8 expressive voices"
                ),
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/voices.json"),
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/tokens.txt"),
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/config.json")
                ].compactMap { $0 }
            ),

            // Kokoro - High quality multilingual
            ModelInfo(
                id: "sherpa-kokoro-en-v0.19",
                name: "Kokoro English",
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/model.onnx"),
                estimatedMemory: 150_000_000,
                downloadSize: 82_000_000,
                metadata: ModelInfoMetadata(
                    tags: ["tts", "sherpa-onnx", "multilingual", "high-quality"],
                    description: "High-quality English TTS with 11+ natural voices"
                ),
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/voices.bin"),
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/tokens.txt"),
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/espeak-ng-data.tar.gz")
                ].compactMap { $0 }
            ),

            // VITS - Good quality, wide language support
            ModelInfo(
                id: "sherpa-vits-en-us-v1.0",
                name: "VITS English US",
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"),
                estimatedMemory: 100_000_000,
                downloadSize: 63_000_000,
                metadata: ModelInfoMetadata(
                    tags: ["tts", "sherpa-onnx", "vits"],
                    description: "VITS-based TTS with natural prosody"
                ),
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json")
                ].compactMap { $0 }
            ),

            // Matcha - Best quality, largest model
            ModelInfo(
                id: "sherpa-matcha-en-v1.0",
                name: "Matcha English",
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/model.onnx"),
                estimatedMemory: 300_000_000,
                downloadSize: 150_000_000,
                metadata: ModelInfoMetadata(
                    tags: ["tts", "sherpa-onnx", "matcha", "high-quality"],
                    description: "State-of-the-art neural TTS with exceptional quality"
                ),
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/config.json"),
                    URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/vocoder.onnx")
                ].compactMap { $0 }
            )
        ]
    }

    /// Get model info by ID
    func getModel(by id: String) -> ModelInfo? {
        return createModelDefinitions().first { $0.id == id }
    }

    /// Select optimal model based on device capabilities
    func selectOptimalModel() -> String {
        // TODO: Implement device capability detection
        // Consider available memory, CPU performance, etc.

        // For now, return the smallest model
        return "sherpa-kitten-nano-v0.1"
    }
}
