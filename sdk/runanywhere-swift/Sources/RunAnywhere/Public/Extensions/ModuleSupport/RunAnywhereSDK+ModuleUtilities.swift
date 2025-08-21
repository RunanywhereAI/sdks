import Foundation

// MARK: - Module Integration Utilities

/// Helper utilities for modules to integrate with SDK services
public struct ModuleIntegrationHelper {
    private let sdk: RunAnywhereSDK

    public init(sdk: RunAnywhereSDK = .shared) {
        self.sdk = sdk
    }

    /// Download a model with progress tracking
    /// - Parameters:
    ///   - modelId: Model identifier
    ///   - progressHandler: Optional progress handler
    /// - Returns: Local path to downloaded model
    public func downloadModelWithProgress(
        _ modelId: String,
        progressHandler: ((DownloadProgress) -> Void)? = nil
    ) async throws -> URL {
        // Start download
        let downloadTask = try await sdk.downloadModel(modelId)

        // Track progress if handler provided
        if let progressHandler = progressHandler {
            for await progress in downloadTask.progress {
                progressHandler(progress)
            }
        } else {
            // Just wait for completion
            for await _ in downloadTask.progress {
                // Progress updates ignored
            }
        }

        // Get final path
        guard let localPath = await sdk.getModelLocalPath(for: modelId) else {
            throw SDKError.modelNotFound(modelId)
        }

        return localPath
    }

    /// Register and download a model from URL
    /// - Parameters:
    ///   - name: Display name
    ///   - url: Download URL
    ///   - framework: Framework identifier
    ///   - additionalFiles: Additional files to download
    /// - Returns: Local path to downloaded model
    public func registerAndDownloadModel(
        name: String,
        url: URL,
        framework: LLMFramework,
        additionalFiles: [URL] = []
    ) async throws -> URL {
        // Create model info with additional files
        let model = sdk.addModelFromURL(
            name: name,
            url: url,
            framework: framework,
            estimatedSize: nil
        )

        // Download main model and additional files
        return try await downloadModelWithProgress(model.id)
    }

    /// Check for model updates
    /// - Parameter modelId: Model identifier
    /// - Returns: true if an update is available
    public func checkForModelUpdate(_ modelId: String) async -> Bool {
        // This could check against a remote registry or version file
        // For now, return false (no update)
        return false
    }

    /// Get all models for a specific framework
    /// - Parameter framework: Framework identifier
    /// - Returns: Array of models for the framework
    public func getModelsForFramework(_ framework: String) async throws -> [ModelInfo] {
        let allModels = try await sdk.listAvailableModels()
        // Use explicit filter to avoid Predicate type confusion
        var filteredModels: [ModelInfo] = []
        for model in allModels {
            if case .custom(let fw) = model.framework, fw == framework {
                filteredModels.append(model)
            }
        }
        return filteredModels
    }
}

// MARK: - Module Lifecycle Support

public protocol ModuleLifecycle {
    /// Called when module is being initialized
    func moduleWillInitialize() async throws

    /// Called after module is initialized
    func moduleDidInitialize() async

    /// Called when module is being deinitialized
    func moduleWillDeinitialize() async

    /// Called to check if module is ready
    func isModuleReady() -> Bool
}

/// Default implementation for optional methods
public extension ModuleLifecycle {
    func moduleWillInitialize() async throws {}
    func moduleDidInitialize() async {}
    func moduleWillDeinitialize() async {}
    func isModuleReady() -> Bool { true }
}

// MARK: - Module Configuration

/// Base configuration for modules
public protocol ModuleConfiguration {
    /// Module identifier
    var moduleId: String { get }

    /// Module version
    var version: String { get }

    /// Required SDK version
    var requiredSDKVersion: String { get }

    /// Module dependencies
    var dependencies: [String] { get }
}

// MARK: - Module Error Handling

/// Standard errors for module operations
public enum ModuleError: LocalizedError {
    case moduleNotFound(String)
    case incompatibleSDKVersion(required: String, current: String)
    case missingDependency(String)
    case initializationFailed(String)
    case modelDownloadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .moduleNotFound(let module):
            return "Module '\(module)' not found. Ensure it's added to your app dependencies."
        case .incompatibleSDKVersion(let required, let current):
            return "Module requires SDK version \(required), but current version is \(current)"
        case .missingDependency(let dependency):
            return "Missing required dependency: \(dependency)"
        case .initializationFailed(let reason):
            return "Module initialization failed: \(reason)"
        case .modelDownloadFailed(let modelId):
            return "Failed to download model: \(modelId)"
        }
    }
}

// MARK: - Module Registry

/// Registry for tracking available modules
public class ModuleRegistry {
    private var registeredModules: [String: ModuleConfiguration] = [:]
    private let queue = DispatchQueue(label: "com.runanywhere.moduleregistry", attributes: .concurrent)

    public static let shared = ModuleRegistry()

    private init() {}

    /// Register a module
    public func register(_ configuration: ModuleConfiguration) {
        queue.async(flags: .barrier) {
            self.registeredModules[configuration.moduleId] = configuration
        }
    }

    /// Get all registered modules
    public func getAllModules() -> [ModuleConfiguration] {
        queue.sync {
            Array(registeredModules.values)
        }
    }

    /// Check if a module is registered
    public func isModuleRegistered(_ moduleId: String) -> Bool {
        queue.sync {
            registeredModules[moduleId] != nil
        }
    }

    /// Get module configuration
    public func getModuleConfiguration(_ moduleId: String) -> ModuleConfiguration? {
        queue.sync {
            registeredModules[moduleId]
        }
    }
}
