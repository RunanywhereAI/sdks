import Foundation

// MARK: - LLM Module Support

/// Extensions for LLM-related modules (LLMSwift, MLX, etc.)
extension RunAnywhereSDK {

    // MARK: - LLM Module Types

    /// Available LLM module types
    public enum LLMModuleType {
        /// LLMSwift module for local inference
        case llmSwift
        /// MLX module for Apple Silicon optimization
        case mlx
        /// Custom LLM service
        case custom(any LLMService)
    }

    /// Create an LLM service from an available module
    /// - Parameter moduleType: The LLM module type to create
    /// - Returns: LLMService instance if available, nil otherwise
    public func createModuleLLMService(_ moduleType: LLMModuleType) async -> (any LLMService)? {
        switch moduleType {
        case .llmSwift:
            return createLLMSwiftService()

        case .mlx:
            return createMLXService()

        case .custom(let service):
            return service
        }
    }

    /// Create LLMSwift service if module is available
    private func createLLMSwiftService() -> (any LLMService)? {
        let className = "LLMSwiftModule.LLMSwiftService"

        guard let llmClass = NSClassFromString(className) as? any LLMService.Type else {
            print("[RunAnywhereSDK] LLMSwift module not found. Add it to your app dependencies.")
            return nil
        }

        return llmClass.init()
    }

    /// Create MLX service if module is available
    private func createMLXService() -> (any LLMService)? {
        let className = "MLXModule.MLXLLMService"

        guard let mlxClass = NSClassFromString(className) as? any LLMService.Type else {
            print("[RunAnywhereSDK] MLX module not found. Add it to your app dependencies.")
            return nil
        }

        return mlxClass.init()
    }

    // MARK: - Module Availability

    /// Check if LLMSwift module is available
    public var isLLMSwiftAvailable: Bool {
        return Self.isModuleAvailable("LLMSwiftModule.LLMSwiftService")
    }

    /// Check if MLX module is available
    public var isMLXAvailable: Bool {
        return Self.isModuleAvailable("MLXModule.MLXLLMService")
    }
}

// MARK: - LLM Module Factory

/// Factory for creating LLM module services
public struct LLMModuleFactory {

    /// Create the best available LLM service for the model
    public static func createBestAvailableLLM(for modelId: String) async -> (any LLMService)? {
        let sdk = RunAnywhereSDK.shared

        // Determine best framework based on model format
        if modelId.contains("mlx") && sdk.isMLXAvailable {
            return await sdk.createModuleLLMService(.mlx)
        }

        if modelId.contains("gguf") && sdk.isLLMSwiftAvailable {
            return await sdk.createModuleLLMService(.llmSwift)
        }

        // Try any available
        if sdk.isLLMSwiftAvailable {
            return await sdk.createModuleLLMService(.llmSwift)
        }

        if sdk.isMLXAvailable {
            return await sdk.createModuleLLMService(.mlx)
        }

        return nil
    }
}

// MARK: - LLM Service Protocol

/// Protocol that LLM modules must conform to
public protocol LLMService {
    init()
    func initialize() async throws
    func loadModel(_ modelPath: URL) async throws
    func generate(prompt: String, options: GenerationOptions?) async throws -> String
    func generateStream(prompt: String, options: GenerationOptions?) -> AsyncThrowingStream<String, Error>
    func unloadModel() async
}

// MARK: - LLM Module Configuration

/// Configuration for LLM modules
public struct LLMModuleConfig {
    /// Maximum context length
    public let maxContextLength: Int

    /// GPU acceleration enabled
    public let useGPU: Bool

    /// Number of threads for CPU inference
    public let cpuThreads: Int

    /// Memory limit in bytes
    public let memoryLimit: Int64?

    public init(
        maxContextLength: Int = 2048,
        useGPU: Bool = true,
        cpuThreads: Int = 4,
        memoryLimit: Int64? = nil
    ) {
        self.maxContextLength = maxContextLength
        self.useGPU = useGPU
        self.cpuThreads = cpuThreads
        self.memoryLimit = memoryLimit
    }
}
