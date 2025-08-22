import Foundation

/// TTS provider options
public enum TTSProvider: String, CaseIterable {
    /// System TTS (AVSpeechSynthesizer)
    case system
    /// Sherpa-ONNX TTS (high-quality neural voices)
    case sherpaONNX
    /// Custom TTS implementation
    case custom
}

/// Configuration for Text-to-Speech processing
public struct VoiceTTSConfig {
    /// TTS provider to use
    public let provider: TTSProvider

    /// Model ID for neural TTS providers (e.g., "sherpa-kitten-nano-v0.1")
    public let modelId: String?

    /// Voice identifier for synthesis
    public let voice: String

    /// Speech rate (0.5 to 2.0, 1.0 is normal)
    public let rate: Float

    /// Voice pitch (0.5 to 2.0, 1.0 is normal)
    public let pitch: Float

    /// Volume (0.0 to 1.0)
    public let volume: Float

    public init(
        provider: TTSProvider = .system,
        modelId: String? = nil,
        voice: String = "system",
        rate: Float = 1.0,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) {
        self.provider = provider
        self.modelId = modelId
        self.voice = voice
        self.rate = rate
        self.pitch = pitch
        self.volume = volume
    }

    /// Convenience initializer for system TTS
    public static func system(
        voice: String = "system",
        rate: Float = 1.0,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) -> VoiceTTSConfig {
        return VoiceTTSConfig(
            provider: .system,
            voice: voice,
            rate: rate,
            pitch: pitch,
            volume: volume
        )
    }

    /// Convenience initializer for Sherpa-ONNX TTS
    public static func sherpaONNX(
        modelId: String = "sherpa-kitten-nano-v0.1",
        voice: String = "expr-voice-2-f",
        rate: Float = 1.0,
        volume: Float = 1.0
    ) -> VoiceTTSConfig {
        return VoiceTTSConfig(
            provider: .sherpaONNX,
            modelId: modelId,
            voice: voice,
            rate: rate,
            pitch: 1.0, // Pitch not supported in Sherpa-ONNX
            volume: volume
        )
    }
}
