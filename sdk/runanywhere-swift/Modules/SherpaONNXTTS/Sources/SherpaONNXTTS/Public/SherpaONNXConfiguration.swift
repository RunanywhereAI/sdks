import Foundation

/// Configuration for Sherpa-ONNX TTS engine
public struct SherpaONNXConfiguration {

    /// Path to the model directory containing all model files
    public let modelPath: URL

    /// Type of model being used
    public let modelType: SherpaONNXModelType

    /// Number of threads to use for inference
    public let numThreads: Int

    /// Sample rate for output audio
    public let sampleRate: Int

    /// Enable debug logging
    public let debug: Bool

    /// Max sentence length for chunking
    public let maxSentenceLength: Int

    public init(
        modelPath: URL,
        modelType: SherpaONNXModelType,
        numThreads: Int = 2,
        sampleRate: Int = 16000,
        debug: Bool = false,
        maxSentenceLength: Int = 1024
    ) {
        self.modelPath = modelPath
        self.modelType = modelType
        self.numThreads = numThreads
        self.sampleRate = sampleRate
        self.debug = debug
        self.maxSentenceLength = maxSentenceLength
    }
}

/// Supported Sherpa-ONNX model types
public enum SherpaONNXModelType: String, CaseIterable {
    case kitten = "kitten"
    case kokoro = "kokoro"
    case vits = "vits"
    case matcha = "matcha"
    case piper = "piper"

    /// Human-readable name for the model type
    public var displayName: String {
        switch self {
        case .kitten:
            return "Kitten TTS"
        case .kokoro:
            return "Kokoro"
        case .vits:
            return "VITS"
        case .matcha:
            return "Matcha"
        case .piper:
            return "Piper"
        }
    }

    /// Estimated memory usage in bytes
    public var estimatedMemoryUsage: Int {
        switch self {
        case .kitten:
            return 50_000_000  // ~50MB
        case .kokoro:
            return 150_000_000 // ~150MB
        case .vits:
            return 100_000_000 // ~100MB
        case .matcha:
            return 300_000_000 // ~300MB
        case .piper:
            return 100_000_000 // ~100MB
        }
    }
}

/// Errors specific to Sherpa-ONNX TTS
public enum SherpaONNXError: LocalizedError {
    case notInitialized
    case modelNotFound(String)
    case voiceNotFound(String)
    case synthesisFailure(String)
    case invalidConfiguration(String)
    case frameworkNotLoaded
    case unsupportedModelType(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Sherpa-ONNX TTS service is not initialized"
        case .modelNotFound(let modelId):
            return "Model not found: \(modelId)"
        case .voiceNotFound(let voiceId):
            return "Voice not found: \(voiceId)"
        case .synthesisFailure(let reason):
            return "Synthesis failed: \(reason)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .frameworkNotLoaded:
            return "Sherpa-ONNX framework not loaded"
        case .unsupportedModelType(let type):
            return "Unsupported model type: \(type)"
        }
    }
}
