import Foundation
import RunAnywhereSDK
#if canImport(FoundationModels)
import FoundationModels
#endif

// Import RunAnywhereSDK types explicitly to avoid ambiguity
import struct RunAnywhereSDK.GenerationOptions

/// Adapter for Apple Foundation Models framework
/// Provides access to Apple's on-device language models
@available(iOS 18.2, macOS 15.2, *)
public class FoundationModelsAdapter: FrameworkAdapter {
    public var framework: LLMFramework { .foundationModels }

    public var supportedFormats: [ModelFormat] {
        [.mlmodel, .mlpackage]
    }

    private var hardwareConfig: HardwareConfiguration?

    public init() {}

    public func canHandle(model: ModelInfo) -> Bool {
        // Check format support
        guard supportedFormats.contains(model.format) else { 
            print("🎯 DEBUG: FoundationModelsAdapter - Format not supported: \(model.format)")
            return false 
        }

        #if canImport(FoundationModels)
        print("🎯 DEBUG: FoundationModels framework IS available")
        if #available(iOS 26.0, macOS 26.0, *) {
            print("🎯 DEBUG: iOS 26.0+ version check passed")
            // Check if Apple Intelligence is available
            let systemModel = SystemLanguageModel.default
            print("🎯 DEBUG: SystemLanguageModel availability: \(systemModel.availability)")
            if case .available = systemModel.availability {
                print("🎯 DEBUG: FoundationModelsAdapter CAN handle model: \(model.name)")
                return true
            } else {
                print("🎯 DEBUG: SystemLanguageModel not available")
            }
        } else {
            print("🎯 DEBUG: iOS version check failed")
        }
        #else
        print("🎯 DEBUG: FoundationModels framework NOT available")
        #endif
        
        print("🎯 DEBUG: FoundationModelsAdapter CANNOT handle model: \(model.name)")
        return false
    }

    public func createService() -> LLMService {
        return FoundationModelsService(hardwareConfig: hardwareConfig)
    }

    public func loadModel(_ model: ModelInfo) async throws -> LLMService {
        guard let localPath = model.localPath else {
            throw FrameworkError(
                framework: framework,
                underlying: LLMServiceError.modelNotLoaded,
                context: "Foundation model not available"
            )
        }

        let service = FoundationModelsService(hardwareConfig: hardwareConfig)
        try await service.initialize(modelPath: localPath.path)
        return service
    }

    public func configure(with hardware: HardwareConfiguration) async {
        self.hardwareConfig = hardware
    }

    public func estimateMemoryUsage(for model: ModelInfo) -> Int64 {
        // Foundation models are optimized for Apple Silicon
        let baseSize = model.estimatedMemory
        let overhead = Int64(Double(baseSize) * 0.1) // 10% overhead
        return baseSize + overhead
    }

    public func optimalConfiguration(for model: ModelInfo) -> HardwareConfiguration {
        return HardwareConfiguration(
            primaryAccelerator: .neuralEngine,
            fallbackAccelerator: .gpu,
            memoryMode: .balanced,
            threadCount: 2,
            useQuantization: false,
            quantizationBits: 16
        )
    }
}

/// Service implementation for Apple Foundation Models
/// Uses SystemLanguageModel for on-device language generation
@available(iOS 18.2, macOS 15.2, *)
class FoundationModelsService: LLMService {
    private var hardwareConfig: HardwareConfiguration?
    private var _modelInfo: LoadedModelInfo?
    private var _isReady = false
    
    // Store the language model and session as Any? to avoid version check issues
    private var languageModel: Any?
    private var session: Any?
    
    var isReady: Bool { _isReady }
    var modelInfo: LoadedModelInfo? { _modelInfo }

    init(hardwareConfig: HardwareConfiguration?) {
        self.hardwareConfig = hardwareConfig
    }

    func initialize(modelPath: String) async throws {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            // Initialize the system language model
            let model = SystemLanguageModel.default
            self.languageModel = model
            
            // Check availability
            
            switch model.availability {
            case .available:
                // Model is available, set up model info
                setupModelInfo(modelPath: modelPath)
                _isReady = true
                
            case .unavailable(let reason):
                let errorMessage = getAvailabilityErrorMessage(reason)
                throw LLMServiceError.generationFailed(errorMessage)
                
            @unknown default:
                throw LLMServiceError.modelNotLoaded
            }
        } else {
            throw LLMServiceError.generationFailed("Foundation Models requires iOS 18.2 or newer")
        }
        #else
        throw LLMServiceError.generationFailed("FoundationModels framework not available")
        #endif
    }

    func generate(prompt: String, options: GenerationOptions) async throws -> String {
        guard isReady else {
            throw LLMServiceError.notInitialized
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            guard let model = languageModel as? SystemLanguageModel else {
                throw LLMServiceError.modelNotLoaded
            }
            
            // Check availability again before generation
            guard case .available = model.availability else {
                throw LLMServiceError.modelNotLoaded
            }
            
            // Create a new session for this generation
            let transcript = Transcript(entries: [])
            session = LanguageModelSession(transcript: transcript)
            
            guard let currentSession = session as? LanguageModelSession else {
                throw LLMServiceError.generationFailed("Failed to create session")
            }
            
            do {
                // Configure generation options using FoundationModels' GenerationOptions
                var fmOptions = FoundationModels.GenerationOptions()
                
                // Map our SDK options to FoundationModels options
                fmOptions.temperature = Double(options.temperature)
                if options.maxTokens > 0 {
                    fmOptions.maximumResponseTokens = options.maxTokens
                }
                
                // Generate response
                let response = try await currentSession.respond(
                    to: prompt,
                    options: fmOptions
                )
                
                return response.content
            } catch {
                throw LLMServiceError.generationFailed(error.localizedDescription)
            }
        } else {
            throw LLMServiceError.generationFailed("Foundation Models requires iOS 18.2 or newer")
        }
        #else
        throw LLMServiceError.generationFailed("FoundationModels framework not available")
        #endif
    }
    
    private func setupModelInfo(modelPath: String) {
        // Extract model name from path
        let modelName = URL(fileURLWithPath: modelPath).deletingPathExtension().lastPathComponent
        
        // Get supported languages
        var supportedLanguages = 0
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let model = languageModel as? SystemLanguageModel {
                supportedLanguages = model.supportedLanguages.count
            }
        }
        #endif
        
        _modelInfo = LoadedModelInfo(
            id: UUID().uuidString,
            name: "Apple Intelligence (\(modelName))",
            framework: .foundationModels,
            format: .mlmodel,
            memoryUsage: 500_000_000, // Estimated 500MB
            contextLength: 8192, // Default context length
            configuration: hardwareConfig ?? HardwareConfiguration()
        )
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func getAvailabilityErrorMessage(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        // Handle the reason generically since exact case names may vary
        return "Apple Intelligence is not available on this device. Please ensure you have a compatible device and that Apple Intelligence is enabled in Settings."
    }
    #endif

    func streamGenerate(
        prompt: String,
        options: GenerationOptions,
        onToken: @escaping (String) -> Void
    ) async throws {
        guard isReady else {
            throw LLMServiceError.notInitialized
        }
        
        // Generate the full response first
        let fullResponse = try await generate(prompt: prompt, options: options)
        
        // Stream it token by token
        let words = fullResponse.split(separator: " ")
        for word in words {
            onToken(String(word) + " ")
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds per word
        }
    }

    func cleanup() async {
        _isReady = false
        _modelInfo = nil
        languageModel = nil
        session = nil
    }

    func getModelMemoryUsage() async throws -> Int64 {
        return _modelInfo?.memoryUsage ?? 0
    }
}