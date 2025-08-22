import Foundation
import RunAnywhereSDK
import AVFoundation
import os

/// Sherpa-ONNX based Text-to-Speech service
/// Provides high-quality neural TTS with multiple voice models
public final class SherpaONNXTTSService: TextToSpeechService {

    // MARK: - Properties

    private let sdk: RunAnywhereSDK
    private let modelManager: SherpaONNXModelManager
    private let downloadStrategy: SherpaONNXDownloadStrategy
    private var wrapper: SherpaONNXWrapper?

    private var currentModelId: String?
    private var isInitialized = false
    private let queue = DispatchQueue(label: "com.runanywhere.sherpaonnxtts", attributes: .concurrent)

    private let logger = Logger(
        subsystem: "com.runanywhere.sdk",
        category: "SherpaONNXTTS"
    )

    // MARK: - TextToSpeechService Properties

    public var availableVoices: [VoiceInfo] {
        queue.sync {
            wrapper?.availableVoices ?? []
        }
    }

    public var currentVoice: VoiceInfo? {
        queue.sync {
            wrapper?.currentVoice
        }
    }

    public var rate: Float = 1.0
    public var pitch: Float = 1.0
    public var volume: Float = 1.0

    // MARK: - Initialization

    /// Initialize with SDK instance (two-phase pattern)
    public init(sdk: RunAnywhereSDK = .shared) {
        self.sdk = sdk
        self.modelManager = SherpaONNXModelManager(sdk: sdk)
        self.downloadStrategy = SherpaONNXDownloadStrategy()

        // Register models and download strategy immediately
        modelManager.registerModels()
        sdk.registerModuleDownloadStrategy(downloadStrategy)

        logger.info("SherpaONNXTTS module initialized")
    }

    /// Async initialization - downloads models and prepares TTS engine
    public func initialize() async throws {
        try await queue.sync {
            guard !isInitialized else {
                logger.debug("Already initialized")
                return
            }
        }

        logger.info("Starting async initialization")

        // Select optimal model based on device capabilities
        let modelId = selectOptimalModel()
        logger.info("Selected model: \(modelId)")

        // Download model if needed using SDK infrastructure
        if !sdk.isModelDownloaded(modelId) {
            logger.info("Downloading model: \(modelId)")

            let helper = ModuleIntegrationHelper(sdk: sdk)
            _ = try await helper.downloadModelWithProgress(modelId) { progress in
                self.logger.debug("Download progress: \(progress.percentage)%")
            }
        }

        // Get local path from SDK
        guard let modelPath = await sdk.getModelLocalPath(for: modelId) else {
            throw SherpaONNXError.modelNotFound(modelId)
        }

        logger.info("Model path: \(modelPath.path)")

        // Initialize Sherpa-ONNX wrapper
        let config = SherpaONNXConfiguration(
            modelPath: modelPath,
            modelType: modelTypeForId(modelId)
        )

        let newWrapper = try await SherpaONNXWrapper(configuration: config)

        await queue.async(flags: .barrier) {
            self.wrapper = newWrapper
            self.currentModelId = modelId
            self.isInitialized = true
        }

        logger.info("SherpaONNXTTS initialization complete")
    }

    // MARK: - TextToSpeechService Protocol

    public func synthesize(text: String, options: TTSOptions?) async throws -> Data {
        guard isInitialized, let wrapper = wrapper else {
            throw SherpaONNXError.notInitialized
        }

        logger.debug("Synthesizing text: \(text.prefix(50))...")

        // Apply options if provided
        if let options = options {
            if let voiceId = options.voice {
                try await setVoice(voiceId)
            }
            self.rate = options.rate ?? 1.0
            self.pitch = options.pitch ?? 1.0
            self.volume = options.volume ?? 1.0
        }

        // Generate audio using wrapper
        let audioData = try await wrapper.synthesize(
            text: text,
            rate: rate,
            pitch: pitch,
            volume: volume
        )

        logger.debug("Generated \(audioData.count) bytes of audio")
        return audioData
    }

    public func synthesizeStream(text: String, options: TTSOptions?) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard isInitialized, let wrapper = wrapper else {
                        throw SherpaONNXError.notInitialized
                    }

                    // Apply options
                    if let options = options {
                        if let voiceId = options.voice {
                            try await setVoice(voiceId)
                        }
                        self.rate = options.rate ?? 1.0
                        self.pitch = options.pitch ?? 1.0
                        self.volume = options.volume ?? 1.0
                    }

                    // Stream synthesis
                    let stream = wrapper.synthesizeStream(
                        text: text,
                        rate: rate,
                        pitch: pitch,
                        volume: volume
                    )

                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func setVoice(_ voiceIdentifier: String) async throws {
        guard let wrapper = wrapper else {
            throw SherpaONNXError.notInitialized
        }

        try await wrapper.setVoice(voiceIdentifier)
        logger.debug("Voice changed to: \(voiceIdentifier)")
    }

    public func stop() {
        queue.async(flags: .barrier) {
            self.wrapper?.stop()
        }
        logger.debug("TTS stopped")
    }

    public func pause() {
        queue.async(flags: .barrier) {
            self.wrapper?.pause()
        }
        logger.debug("TTS paused")
    }

    public func resume() {
        queue.async(flags: .barrier) {
            self.wrapper?.resume()
        }
        logger.debug("TTS resumed")
    }

    // MARK: - Private Methods

    private func selectOptimalModel() -> String {
        // TODO: Implement device capability detection
        // For now, use the smallest model
        return "sherpa-kitten-nano-v0.1"
    }

    private func modelTypeForId(_ modelId: String) -> SherpaONNXModelType {
        switch modelId {
        case let id where id.contains("kitten"):
            return .kitten
        case let id where id.contains("kokoro"):
            return .kokoro
        case let id where id.contains("vits"):
            return .vits
        case let id where id.contains("matcha"):
            return .matcha
        default:
            return .kitten
        }
    }

    // MARK: - Module Lifecycle

    public func moduleWillTerminate() {
        wrapper?.cleanup()
        logger.info("Module terminating")
    }
}

// MARK: - ModuleLifecycle Conformance

extension SherpaONNXTTSService: ModuleLifecycle {
    public func moduleWillInitialize() async throws {
        logger.info("Module will initialize")
    }

    public func moduleDidInitialize() async {
        logger.info("Module did initialize")
    }

    public func isModuleReady() -> Bool {
        return isInitialized
    }
}
