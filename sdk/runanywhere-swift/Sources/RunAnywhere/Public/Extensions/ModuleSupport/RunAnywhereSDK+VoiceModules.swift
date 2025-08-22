import Foundation

// MARK: - Voice Module Support

/// Extensions specifically for voice-related modules (TTS, STT, etc.)
extension RunAnywhereSDK {

    // MARK: - TTS Module Support

    /// Available TTS module types
    public enum TTSModuleType {
        /// Sherpa-ONNX TTS module
        case sherpaONNX
        /// Custom TTS service
        case custom(any TextToSpeechService)
    }

    /// Create a TTS service from an available module
    /// - Parameter moduleType: The TTS module type to create
    /// - Returns: TextToSpeechService instance if available, nil otherwise
    public func createTTSModuleService(_ moduleType: TTSModuleType) async -> (any TextToSpeechService)? {
        switch moduleType {
        case .sherpaONNX:
            return createSherpaONNXTTS()

        case .custom(let service):
            return service
        }
    }

    /// Create Sherpa-ONNX TTS if module is available
    private func createSherpaONNXTTS() -> (any TextToSpeechService)? {
        // Check if SherpaONNXTTS module is available
        let className = "SherpaONNXTTS.SherpaONNXTTSService"

        guard NSClassFromString(className) != nil else {
            print("[RunAnywhereSDK] SherpaONNXTTS module not found. Add it to your app dependencies.")
            return nil
        }

        // Module should register itself and provide factory when imported
        // For now, return nil - actual instantiation will be handled by the module
        return nil
    }

    // MARK: - STT Module Support

    /// Available STT module types
    public enum STTModuleType {
        /// WhisperKit STT module
        case whisperKit
        /// Custom STT service
        case custom(any SpeechToTextService)
    }

    /// Create an STT service from an available module
    /// - Parameter moduleType: The STT module type to create
    /// - Returns: SpeechToTextService instance if available, nil otherwise
    public func createModuleSTTService(_ moduleType: STTModuleType) async -> (any SpeechToTextService)? {
        switch moduleType {
        case .whisperKit:
            return createWhisperKitSTT()

        case .custom(let service):
            return service
        }
    }

    /// Create WhisperKit STT if module is available
    private func createWhisperKitSTT() -> (any SpeechToTextService)? {
        // Check if WhisperKit module is available
        let className = "WhisperKitModule.WhisperKitSTTService"

        guard NSClassFromString(className) != nil else {
            print("[RunAnywhereSDK] WhisperKit module not found. Add it to your app dependencies.")
            return nil
        }

        // Module should register itself and provide factory when imported
        // For now, return nil - actual instantiation will be handled by the module
        return nil
    }

    // MARK: - Voice Pipeline Integration

    /// Create a voice pipeline with module-based services
    /// - Parameter config: Pipeline configuration
    /// - Returns: Configured voice pipeline with module services
    public func createVoicePipelineWithModules(
        config: ModularPipelineConfig
    ) -> VoicePipelineManager {
        let pipeline = createVoicePipeline(config: config)

        // The pipeline will automatically use module services if available
        // through the TTSHandler and other handlers

        return pipeline
    }

    // MARK: - Module Availability Checks

    /// Check if Sherpa-ONNX TTS module is available
    public var isSherpaONNXTTSAvailable: Bool {
        return RunAnywhereSDK.isModuleAvailable("SherpaONNXTTS.SherpaONNXTTSService")
    }

    /// Check if WhisperKit STT module is available
    public var isWhisperKitModuleAvailable: Bool {
        return RunAnywhereSDK.isModuleAvailable("WhisperKitModule.WhisperKitSTTService")
    }

    /// Check if FluidAudio diarization module is available
    public var isFluidAudioDiarizationAvailable: Bool {
        return RunAnywhereSDK.isModuleAvailable("FluidAudioDiarization.FluidAudioDiarization")
    }
}

// MARK: - Voice Module Factory

/// Factory for creating voice-related module services
public struct VoiceModuleFactory {

    /// Create the best available TTS service
    /// Priority: Module TTS > System TTS
    public static func createBestAvailableTTS() async -> any TextToSpeechService {
        let sdk = RunAnywhereSDK.shared

        // Try Sherpa-ONNX first
        if sdk.isSherpaONNXTTSAvailable,
           let sherpaService = await sdk.createTTSModuleService(.sherpaONNX) {
            print("[VoiceModuleFactory] Using Sherpa-ONNX TTS")
            return sherpaService
        }

        // Fallback to system TTS
        print("[VoiceModuleFactory] Using System TTS")
        return SystemTextToSpeechService()
    }

    /// Create TTS service based on configuration
    public static func createTTSService(from config: VoiceTTSConfig) async -> any TextToSpeechService {
        let sdk = RunAnywhereSDK.shared

        switch config.provider {
        case .system:
            return SystemTextToSpeechService()

        case .sherpaONNX:
            if sdk.isSherpaONNXTTSAvailable {
                // Module is available but needs proper instantiation
                // For now, fallback to system until module provides factory
                print("[VoiceModuleFactory] Sherpa-ONNX module detected, awaiting factory implementation")
            }
            // Fallback to system TTS
            return SystemTextToSpeechService()

        case .custom:
            // For custom, the service should be provided separately
            return SystemTextToSpeechService()
        }
    }

    /// Create the best available STT service
    public static func createBestAvailableSTT() async -> (any SpeechToTextService)? {
        let sdk = RunAnywhereSDK.shared

        // Try WhisperKit first
        if sdk.isWhisperKitModuleAvailable,
           let whisperService = await sdk.createModuleSTTService(.whisperKit) {
            print("[VoiceModuleFactory] Using WhisperKit STT")
            return whisperService
        }

        // Could add more STT modules here

        return nil
    }
}

// MARK: - Voice Module Configuration

/// Configuration specific to voice modules
public struct VoiceModuleConfig {
    /// Enable automatic fallback to system services
    public let enableFallback: Bool

    /// Preferred TTS provider
    public let preferredTTS: TTSProvider

    /// Preferred STT provider
    public let preferredSTT: String?

    /// Enable speaker diarization if available
    public let enableDiarization: Bool

    public init(
        enableFallback: Bool = true,
        preferredTTS: TTSProvider = .system,
        preferredSTT: String? = nil,
        enableDiarization: Bool = false
    ) {
        self.enableFallback = enableFallback
        self.preferredTTS = preferredTTS
        self.preferredSTT = preferredSTT
        self.enableDiarization = enableDiarization
    }
}

// MARK: - Protocol for Speech Services

/// Protocol that STT modules must conform to
public protocol SpeechToTextService {
    init()
    func initialize() async throws
    func transcribe(audio: Data) async throws -> String
    func transcribeStream(audio: AsyncStream<Data>) async throws -> AsyncStream<String>
}

// MARK: - Voice Module Events

/// Events specific to voice modules
public enum VoiceModuleEvent {
    /// TTS module loaded
    case ttsModuleLoaded(String)
    /// STT module loaded
    case sttModuleLoaded(String)
    /// Module fallback occurred
    case moduleFallback(from: String, to: String)
    /// Module initialization failed
    case moduleInitFailed(String, Error)
}
