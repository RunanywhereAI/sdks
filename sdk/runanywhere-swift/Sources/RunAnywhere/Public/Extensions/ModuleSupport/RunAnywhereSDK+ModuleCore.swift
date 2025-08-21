import Foundation

// MARK: - Core Module Support

/// Core extensions for external module support
extension RunAnywhereSDK {

    // MARK: - Module Discovery

    /// Check if a module class is available
    /// - Parameter className: Full class name including module (e.g., "SherpaONNXTTS.SherpaONNXTTSService")
    /// - Returns: true if the class is available
    public static func isModuleAvailable(_ className: String) -> Bool {
        return NSClassFromString(className) != nil
    }

    // MARK: - Framework Storage Management

    /// Get the storage directory for a specific framework
    /// External modules can use this to store framework-specific files
    /// - Parameter framework: The framework identifier (e.g., "sherpa-onnx", "whisperkit", "llmswift")
    /// - Returns: URL to the framework's storage directory
    public func getFrameworkStorageDirectory(for framework: String) throws -> URL {
        return try serviceContainer.fileManager.getFrameworkFolder(framework)
    }

    /// Create a cache directory for a module
    /// - Parameter moduleId: Unique identifier for the module
    /// - Returns: URL to the module's cache directory
    public func createModuleCache(moduleId: String) throws -> URL {
        let documentsFolder = try serviceContainer.fileManager.getDocumentsFolder()
        let cacheFolder = try documentsFolder.createSubfolderIfNeeded(withName: "Cache")
        let moduleFolder = try cacheFolder.createSubfolderIfNeeded(withName: moduleId)
        return moduleFolder.url
    }

    /// Clear cache for a specific module
    /// - Parameter moduleId: Unique identifier for the module
    public func clearModuleCache(moduleId: String) throws {
        let documentsFolder = try serviceContainer.fileManager.getDocumentsFolder()
        if let cacheFolder = try? documentsFolder.subfolder(named: "Cache"),
           let moduleFolder = try? cacheFolder.subfolder(named: moduleId) {
            try moduleFolder.delete()
        }
    }

    // MARK: - Download Service Access

    /// Access to the download service for external modules
    /// Modules can use this to download their models using SDK infrastructure
    public var downloadService: any DownloadManager {
        return serviceContainer.downloadService
    }

    /// Register a custom download strategy for modules
    /// - Parameter strategy: The download strategy to register
    public func registerModuleDownloadStrategy(_ strategy: any DownloadStrategy) {
        registerDownloadStrategy(strategy)
    }

    // MARK: - Model Management

    /// Register a module's models with the SDK registry
    /// - Parameter models: Array of models to register
    public func registerModuleModels(_ models: [ModelInfo]) {
        guard let registry = serviceContainer.modelRegistry as? RegistryService else {
            print("[RunAnywhereSDK] Failed to register module models: Registry service not available")
            return
        }

        for model in models {
            registry.registerModel(model)
        }
    }

    /// Get the local path for a downloaded model
    /// - Parameter modelId: The model identifier
    /// - Returns: Local file URL if model is downloaded, nil otherwise
    public func getModelLocalPath(for modelId: String) async -> URL? {
        guard let model = serviceContainer.modelRegistry.getModel(by: modelId) else {
            return nil
        }
        return model.localPath
    }

    /// Check if a model is downloaded
    /// - Parameter modelId: The model identifier
    /// - Returns: true if model is downloaded locally
    public func isModelDownloaded(_ modelId: String) -> Bool {
        guard let model = serviceContainer.modelRegistry.getModel(by: modelId) else {
            return false
        }
        return model.localPath != nil
    }
}

// MARK: - Module File Management Protocol

/// Protocol for controlled file management access for external modules
public protocol ModuleFileManagementProtocol {
    /// Get or create a framework-specific folder
    func getFrameworkFolder(_ framework: String) throws -> URL

    /// Get or create a module cache folder
    func getModuleCacheFolder(_ moduleId: String) throws -> URL

    /// Clear module cache
    func clearModuleCache(_ moduleId: String) throws

    /// Get temporary directory for module operations
    func getModuleTempDirectory(_ moduleId: String) throws -> URL
}

// MARK: - File Manager Extension

extension SimplifiedFileManager: ModuleFileManagementProtocol {
    public func getFrameworkFolder(_ framework: String) throws -> URL {
        // Reuse existing getFrameworkFolder which returns URL directly
        return try getFrameworkFolder(framework)
    }

    public func getModuleCacheFolder(_ moduleId: String) throws -> URL {
        let documentsFolder = try getDocumentsFolder()
        let cacheFolder = try documentsFolder.createSubfolderIfNeeded(withName: "Cache")
        let moduleFolder = try cacheFolder.createSubfolderIfNeeded(withName: moduleId)
        return moduleFolder.url
    }

    public func clearModuleCache(_ moduleId: String) throws {
        let documentsFolder = try getDocumentsFolder()
        if let cacheFolder = try? documentsFolder.subfolder(named: "Cache"),
           let moduleFolder = try? cacheFolder.subfolder(named: moduleId) {
            try moduleFolder.delete()
        }
    }

    public func getModuleTempDirectory(_ moduleId: String) throws -> URL {
        let documentsFolder = try getDocumentsFolder()
        let tempFolder = try documentsFolder.createSubfolderIfNeeded(withName: "Temp")
        let moduleFolder = try tempFolder.createSubfolderIfNeeded(withName: moduleId)
        return moduleFolder.url
    }
}
