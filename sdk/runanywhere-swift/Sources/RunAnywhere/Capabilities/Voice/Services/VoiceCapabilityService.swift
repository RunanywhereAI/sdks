import Foundation
import os

/// Main capability coordinator for voice processing
public class VoiceCapabilityService {
    private let logger = SDKLogger(category: "VoiceCapabilityService")

    // Services
    private let sessionManager: VoiceSessionManager
    private let analyticsService: VoiceAnalyticsService

    // State
    private var isInitialized = false

    public init() {
        self.sessionManager = VoiceSessionManager()
        self.analyticsService = VoiceAnalyticsService()
    }

    /// Initialize the voice capability
    public func initialize() async throws {
        guard !isInitialized else {
            logger.debug("Voice capability already initialized")
            return
        }

        logger.info("Initializing voice capability")

        // Initialize sub-services
        await sessionManager.initialize()
        await analyticsService.initialize()

        isInitialized = true
        logger.info("Voice capability initialized successfully")
    }

    /// Create a voice pipeline with the given configuration
    /// - Parameter config: Pipeline configuration
    /// - Returns: Configured voice pipeline manager
    public func createPipeline(config: ModularPipelineConfig) -> VoicePipelineManager {
        logger.debug("Creating voice pipeline with config: \(config.components)")

        // Track pipeline creation
        analyticsService.trackPipelineCreation(config: config)

        // Create and return pipeline
        return VoicePipelineManager(
            config: config,
            vadService: nil,
            voiceService: findVoiceService(for: config.stt?.modelId),
            llmService: findLLMService(for: config.llm?.modelId),
            ttsService: findTTSService(),
            speakerDiarization: nil,
            segmentationStrategy: nil
        )
    }

    /// Process voice with the given configuration
    /// - Parameters:
    ///   - audioStream: Stream of audio chunks
    ///   - config: Pipeline configuration
    /// - Returns: Stream of pipeline events
    public func processVoice(
        audioStream: AsyncStream<VoiceAudioChunk>,
        config: ModularPipelineConfig
    ) -> AsyncThrowingStream<ModularPipelineEvent, Error> {
        let pipeline = createPipeline(config: config)
        return pipeline.process(audioStream: audioStream)
    }

    /// Check if the voice capability is healthy
    /// - Returns: True if healthy, false otherwise
    public func isHealthy() -> Bool {
        return isInitialized && sessionManager.isHealthy() && analyticsService.isHealthy()
    }

    /// Get current metrics for voice processing
    /// - Returns: Voice metrics
    public func getMetrics() -> VoiceMetrics {
        return analyticsService.getMetrics()
    }

    // MARK: - Service Discovery

    /// Find voice service for the given model ID
    public func findVoiceService(for modelId: String?) -> VoiceService? {
        guard let modelId = modelId else { return nil }

        logger.debug("Finding voice service for model: \(modelId)")

        // Access ServiceContainer through shared instance
        let container = ServiceContainer.shared

        // Try to find a model info for this modelId
        if let model = try? container.modelRegistry.getModel(by: modelId) {
            // Find adapter that can handle this model
            if let unifiedAdapter = container.adapterRegistry.findBestAdapter(for: model),
               unifiedAdapter.supportedModalities.contains(FrameworkModality.voiceToText) {
                // Create a voice service from the unified adapter
                if let voiceService = unifiedAdapter.createService(for: FrameworkModality.voiceToText) as? VoiceService {
                    return voiceService
                }
            }
        }

        // Fallback: Find any framework that supports voice-to-text
        let voiceFrameworks = container.adapterRegistry.getFrameworks(for: FrameworkModality.voiceToText)
        if let firstVoiceFramework = voiceFrameworks.first,
           let adapter = container.adapterRegistry.getAdapter(for: firstVoiceFramework) {
            if let voiceService = adapter.createService(for: FrameworkModality.voiceToText) as? VoiceService {
                return voiceService
            }
        }

        return nil
    }

    /// Find LLM service for the given model ID
    private func findLLMService(for modelId: String?) -> LLMService? {
        let container = ServiceContainer.shared

        // First, check if there's already a loaded model in the GenerationService
        if let currentModel = container.generationService.getCurrentModel() {
            return currentModel.service
        }

        // If no model is loaded and a specific modelId is requested
        guard let modelId = modelId else { return nil }

        logger.debug("Finding LLM service for model: \(modelId)")

        if let model = try? container.modelRegistry.getModel(by: modelId) {
            // Find adapter that can handle this model
            if let unifiedAdapter = container.adapterRegistry.findBestAdapter(for: model),
               unifiedAdapter.supportedModalities.contains(FrameworkModality.textToText) {
                // Create an LLM service from the unified adapter
                if let llmService = unifiedAdapter.createService(for: FrameworkModality.textToText) as? LLMService {
                    return llmService
                }
            }
        }

        // Fallback: Find any framework that supports text generation
        let textFrameworks = container.adapterRegistry.getFrameworks(for: FrameworkModality.textToText)
        if let firstTextFramework = textFrameworks.first,
           let adapter = container.adapterRegistry.getAdapter(for: firstTextFramework) {
            if let llmService = adapter.createService(for: FrameworkModality.textToText) as? LLMService {
                return llmService
            }
        }

        return nil
    }

    /// Find TTS service based on configuration
    public func findTTSService() -> TextToSpeechService? {
        logger.debug("Finding TTS service")

        // Check if TTS configuration is provided
        if let ttsConfig = config?.voiceConfig?.tts {
            return findTTSService(for: ttsConfig)
        }

        // Return system TTS service by default
        return SystemTextToSpeechService()
    }

    /// Find TTS service for specific configuration
    private func findTTSService(for config: VoiceTTSConfig) -> TextToSpeechService? {
        switch config.provider {
        case .system:
            logger.debug("Using system TTS service")
            return SystemTextToSpeechService()

        case .sherpaONNX:
            logger.debug("Attempting to use SherpaONNX TTS service")
            // Try to dynamically load SherpaONNX module if available
            if sdk.isSherpaONNXTTSAvailable {
                logger.info("SherpaONNX TTS module is available")
                // Use factory to create module instance
                // Note: This is synchronous for now, async initialization will happen later
                if let moduleService = createSherpaONNXTTSService() {
                    return moduleService
                } else {
                    logger.warning("Failed to create SherpaONNX TTS service, falling back to system TTS")
                    return SystemTextToSpeechService()
                }
            } else {
                logger.warning("SherpaONNX TTS requested but module not available, falling back to system TTS")
                return SystemTextToSpeechService()
            }

        case .custom:
            logger.debug("Custom TTS provider requested")
            // Future: Allow custom TTS implementations
            return SystemTextToSpeechService()
        }
    }

    /// Create SherpaONNX TTS service using dynamic loading
    private func createSherpaONNXTTSService() -> TextToSpeechService? {
        let className = "SherpaONNXTTS.SherpaONNXTTSService"

        guard let moduleClass = NSClassFromString(className) as? NSObject.Type else {
            logger.warning("Could not find class: \(className)")
            return nil
        }

        // Create instance with SDK parameter
        // The module's init expects an SDK instance
        guard let service = moduleClass.init() as? TextToSpeechService else {
            logger.warning("Could not create TTS service from class: \(className)")
            return nil
        }

        logger.info("Successfully created SherpaONNX TTS service")
        return service
    }
}
