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
                description: "Lightweight neural TTS with 8 expressive voices",
                framework: .custom("sherpa-onnx"),
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/model.onnx"),
                downloadSize: 25_000_000,
                estimatedMemoryUsage: 50_000_000,
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/voices.json"),
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/tokens.txt"),
                    URL(string: "https://huggingface.co/KittenML/kitten-tts-nano-0.1/resolve/main/config.json")
                ].compactMap { $0 },
                metadata: [
                    "voices": "8",
                    "languages": "en",
                    "quality": "good",
                    "speed": "fast"
                ]
            ),

            // Kokoro - High quality multilingual
            ModelInfo(
                id: "sherpa-kokoro-en-v0.19",
                name: "Kokoro English",
                description: "High-quality English TTS with 11+ natural voices",
                framework: .custom("sherpa-onnx"),
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/model.onnx"),
                downloadSize: 82_000_000,
                estimatedMemoryUsage: 150_000_000,
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/voices.bin"),
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/tokens.txt"),
                    URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/espeak-ng-data.tar.gz")
                ].compactMap { $0 },
                metadata: [
                    "voices": "11+",
                    "languages": "en,es,fr,de",
                    "quality": "excellent",
                    "speed": "medium"
                ]
            ),

            // VITS - Good quality, wide language support
            ModelInfo(
                id: "sherpa-vits-en-us-v1.0",
                name: "VITS English US",
                description: "VITS-based TTS with natural prosody",
                framework: .custom("sherpa-onnx"),
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"),
                downloadSize: 63_000_000,
                estimatedMemoryUsage: 100_000_000,
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json")
                ].compactMap { $0 },
                metadata: [
                    "voices": "1",
                    "languages": "en-US",
                    "quality": "good",
                    "speed": "fast"
                ]
            ),

            // Matcha - Best quality, largest model
            ModelInfo(
                id: "sherpa-matcha-en-v1.0",
                name: "Matcha English",
                description: "State-of-the-art neural TTS with exceptional quality",
                framework: .custom("sherpa-onnx"),
                format: .onnx,
                downloadURL: URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/model.onnx"),
                downloadSize: 150_000_000,
                estimatedMemoryUsage: 300_000_000,
                alternativeDownloadURLs: [
                    URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/config.json"),
                    URL(string: "https://huggingface.co/matcha-tts/matcha-tts-en/resolve/main/vocoder.onnx")
                ].compactMap { $0 },
                metadata: [
                    "voices": "multiple",
                    "languages": "en",
                    "quality": "best",
                    "speed": "slow"
                ]
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
