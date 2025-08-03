package com.runanywhere.sdk

import com.runanywhere.sdk.configuration.Configuration
import com.runanywhere.sdk.errors.SDKError
import com.runanywhere.sdk.models.*
import com.runanywhere.sdk.services.*
import kotlinx.coroutines.flow.Flow

/**
 * The main entry point for the RunAnywhere SDK
 * Provides functionality for loading models, generating text, and managing the SDK lifecycle
 */
class RunAnywhereSDK private constructor() {
    
    companion object {
        @Volatile
        private var INSTANCE: RunAnywhereSDK? = null
        
        /**
         * Shared instance of the SDK
         */
        val shared: RunAnywhereSDK
            get() = INSTANCE ?: synchronized(this) {
                INSTANCE ?: RunAnywhereSDK().also { INSTANCE = it }
            }
        
        const val VERSION = "1.0.0"
    }
    
    private var configuration: Configuration? = null
    private val serviceContainer = ServiceContainer()
    private var currentModel: ModelInfo? = null
    private var currentService: LLMService? = null
    
    init {
        setupServices()
    }
    
    /**
     * Initialize the SDK with the provided configuration
     * @param configuration The configuration to use
     */
    suspend fun initialize(configuration: Configuration) {
        this.configuration = configuration
        
        // Validate configuration
        serviceContainer.configurationValidator.validate(configuration)
        
        // Bootstrap all services with configuration
        serviceContainer.bootstrap(configuration)
        
        // Start monitoring services if enabled
        if (configuration.enableRealTimeDashboard) {
            serviceContainer.performanceMonitor.startMonitoring()
        }
    }
    
    /**
     * Load a model by identifier
     * @param modelIdentifier The model to load
     * @return Information about the loaded model
     */
    suspend fun loadModel(modelIdentifier: String): ModelInfo {
        configuration ?: throw SDKError.NotInitialized
        
        // Load model through the loading service
        val loadedModel = serviceContainer.modelLoadingService.loadModel(modelIdentifier)
        
        currentModel = loadedModel.model
        currentService = loadedModel.service
        
        // Set the loaded model in the generation service
        serviceContainer.generationService.setCurrentModel(loadedModel)
        
        // Update last used date in metadata
        val metadataStore = ModelMetadataStore()
        metadataStore.updateLastUsed(modelIdentifier)
        
        return loadedModel.model
    }
    
    /**
     * Unload the currently loaded model
     */
    suspend fun unloadModel() {
        val model = currentModel ?: return
        
        serviceContainer.modelLoadingService.unloadModel(model.id)
        
        currentModel = null
        currentService = null
        
        // Clear the model from generation service
        serviceContainer.generationService.setCurrentModel(null)
    }
    
    /**
     * Generate text using the loaded model
     * @param prompt The prompt to generate from
     * @param options Generation options
     * @return The generation result
     */
    suspend fun generate(
        prompt: String,
        options: GenerationOptions? = null
    ): GenerationResult {
        configuration ?: throw SDKError.NotInitialized
        
        currentModel ?: throw SDKError.ModelNotFound("No model loaded")
        
        return serviceContainer.generationService.generate(
            prompt = prompt,
            options = options ?: GenerationOptions()
        )
    }
    
    /**
     * Generate text as a stream
     * @param prompt The prompt to generate from
     * @param options Generation options
     * @return A flow of generated text chunks
     */
    fun generateStream(
        prompt: String,
        options: GenerationOptions? = null
    ): Flow<String> {
        configuration ?: throw SDKError.NotInitialized
        
        currentModel ?: throw SDKError.ModelNotFound("No model loaded")
        
        return serviceContainer.streamingService.generateStream(
            prompt = prompt,
            options = options ?: GenerationOptions()
        )
    }
    
    /**
     * List available models
     * @return Array of available models
     */
    suspend fun listAvailableModels(): List<ModelInfo> {
        configuration ?: throw SDKError.NotInitialized
        
        // Always discover local models to ensure we have the latest
        val discoveredModels = serviceContainer.modelRegistry.discoverModels()
        
        // Also check metadata store for any persisted models
        val metadataStore = ModelMetadataStore()
        val storedModels = metadataStore.loadStoredModels()
        
        // Merge and deduplicate
        val allModels = discoveredModels.toMutableList()
        for (storedModel in storedModels) {
            if (!allModels.any { it.id == storedModel.id }) {
                allModels.add(storedModel)
            }
        }
        
        return allModels
    }
    
    /**
     * Download a model
     * @param modelIdentifier The model to download
     * @return Download task
     */
    suspend fun downloadModel(modelIdentifier: String): DownloadTask {
        configuration ?: throw SDKError.NotInitialized
        
        val model = serviceContainer.modelRegistry.getModel(modelIdentifier)
            ?: throw SDKError.ModelNotFound(modelIdentifier)
        
        return serviceContainer.downloadService.downloadModel(model)
    }
    
    /**
     * Delete a downloaded model
     * @param modelIdentifier The model to delete
     */
    suspend fun deleteModel(modelIdentifier: String) {
        configuration ?: throw SDKError.NotInitialized
        
        // Get model info to find the local path
        val modelInfo = serviceContainer.modelRegistry.getModel(modelIdentifier)
            ?: throw SDKError.ModelNotFound(modelIdentifier)
        
        val localPath = modelInfo.localPath
            ?: throw SDKError.ModelNotFound("Model '$modelIdentifier' not downloaded")
        
        // Extract model ID from the path
        val modelId = localPath.parentFile?.name ?: modelIdentifier
        serviceContainer.fileManager.deleteModel(modelId)
    }
    
    /**
     * Register a framework adapter
     * @param adapter The framework adapter to register
     */
    fun registerFrameworkAdapter(adapter: FrameworkAdapter) {
        serviceContainer.adapterRegistry.register(adapter)
    }
    
    /**
     * Get the list of registered framework adapters
     * @return Dictionary of registered adapters by framework
     */
    fun getRegisteredAdapters(): Map<LLMFramework, FrameworkAdapter> {
        return serviceContainer.adapterRegistry.getRegisteredAdapters()
    }
    
    /**
     * Get available frameworks on this device (based on registered adapters)
     * @return Array of frameworks that have registered adapters
     */
    fun getAvailableFrameworks(): List<LLMFramework> {
        return serviceContainer.adapterRegistry.getAvailableFrameworks()
    }
    
    /**
     * Get detailed framework availability information
     * @return Array of framework availability details
     */
    fun getFrameworkAvailability(): List<FrameworkAvailability> {
        return serviceContainer.adapterRegistry.getFrameworkAvailability()
    }
    
    /**
     * Get models for a specific framework
     * @param framework The framework to filter models for
     * @return Array of models compatible with the framework
     */
    fun getModelsForFramework(framework: LLMFramework): List<ModelInfo> {
        val criteria = ModelCriteria(framework = framework)
        return serviceContainer.modelRegistry.filterModels(criteria)
    }
    
    /**
     * Add a model from URL for download
     * @param name Display name for the model
     * @param url Download URL for the model
     * @param framework Target framework for the model
     * @param estimatedSize Estimated memory usage (optional)
     * @return The created model info
     */
    fun addModelFromURL(
        name: String,
        url: String,
        framework: LLMFramework,
        estimatedSize: Long? = null
    ): ModelInfo {
        return serviceContainer.modelRegistry.addModelFromURL(
            name = name,
            url = url,
            framework = framework,
            estimatedSize = estimatedSize
        )
    }
    
    // MARK: - Internal Service Container Access
    
    /**
     * Access to performance monitoring
     */
    val performanceMonitor: PerformanceMonitor
        get() = serviceContainer.performanceMonitor
    
    /**
     * Access to benchmarking
     */
    val benchmarkSuite: BenchmarkRunner
        get() = serviceContainer.benchmarkRunner
    
    /**
     * Access to file manager for storage operations
     */
    val fileManager: SimplifiedFileManager
        get() = serviceContainer.fileManager
    
    /**
     * Access to A/B testing
     */
    val abTesting: ABTestRunner
        get() = serviceContainer.abTestRunner
    
    private fun setupServices() {
        // Services will be registered in the ServiceContainer
    }
}
