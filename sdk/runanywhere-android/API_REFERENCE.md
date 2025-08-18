# RunAnywhere Android SDK API Reference

## Table of Contents

1. [RunAnywhereSDK](#runanywheresdk)
2. [Configuration](#configuration)
3. [Models](#models)
4. [Generation](#generation)
5. [Framework Management](#framework-management)
6. [Error Handling](#error-handling)
7. [Services](#services)

## RunAnywhereSDK

The main entry point for the RunAnywhere SDK.

### Properties

#### `shared: RunAnywhereSDK`
Shared instance of the SDK (singleton pattern).

#### `VERSION: String`
Current SDK version.

### Methods

#### `initialize(configuration: Configuration)`
Initialize the SDK with the provided configuration.

**Parameters:**
- `configuration`: The configuration to use

**Throws:**
- `RunAnywhereError.InvalidConfiguration`: If configuration is invalid
- `RunAnywhereError.AlreadyInitialized`: If SDK is already initialized

#### `loadModel(modelIdentifier: String): ModelInfo`
Load a model by identifier.

**Parameters:**
- `modelIdentifier`: The model to load

**Returns:**
- `ModelInfo`: Information about the loaded model

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized
- `SDKError.ModelNotFound`: If model is not found

#### `unloadModel()`
Unload the currently loaded model.

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized

#### `generate(prompt: String, options: GenerationOptions? = null): GenerationResult`
Generate text using the loaded model.

**Parameters:**
- `prompt`: The prompt to generate from
- `options`: Generation options (optional)

**Returns:**
- `GenerationResult`: The generation result

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized
- `SDKError.ModelNotFound`: If no model is loaded
- `RunAnywhereError.GenerationFailed`: If generation fails

#### `generateStream(prompt: String, options: GenerationOptions? = null): Flow<String>`
Generate text as a stream.

**Parameters:**
- `prompt`: The prompt to generate from
- `options`: Generation options (optional)

**Returns:**
- `Flow<String>`: A flow of generated text chunks

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized
- `SDKError.ModelNotFound`: If no model is loaded

#### `listAvailableModels(): List<ModelInfo>`
List available models.

**Returns:**
- `List<ModelInfo>`: Array of available models

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized

#### `downloadModel(modelIdentifier: String): DownloadTask`
Download a model.

**Parameters:**
- `modelIdentifier`: The model to download

**Returns:**
- `DownloadTask`: Download task for tracking progress

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized
- `SDKError.ModelNotFound`: If model is not found

#### `deleteModel(modelIdentifier: String)`
Delete a downloaded model.

**Parameters:**
- `modelIdentifier`: The model to delete

**Throws:**
- `SDKError.NotInitialized`: If SDK is not initialized
- `SDKError.ModelNotFound`: If model is not found

#### `registerFrameworkAdapter(adapter: FrameworkAdapter)`
Register a framework adapter.

**Parameters:**
- `adapter`: The framework adapter to register

#### `getRegisteredAdapters(): Map<LLMFramework, FrameworkAdapter>`
Get the list of registered framework adapters.

**Returns:**
- `Map<LLMFramework, FrameworkAdapter>`: Dictionary of registered adapters

#### `getAvailableFrameworks(): List<LLMFramework>`
Get available frameworks on this device.

**Returns:**
- `List<LLMFramework>`: Array of available frameworks

#### `getFrameworkAvailability(): List<FrameworkAvailability>`
Get detailed framework availability information.

**Returns:**
- `List<FrameworkAvailability>`: Array of framework availability details

#### `getModelsForFramework(framework: LLMFramework): List<ModelInfo>`
Get models for a specific framework.

**Parameters:**
- `framework`: The framework to filter models for

**Returns:**
- `List<ModelInfo>`: Array of models compatible with the framework

#### `addModelFromURL(name: String, url: String, framework: LLMFramework, estimatedSize: Long? = null): ModelInfo`
Add a model from URL for download.

**Parameters:**
- `name`: Display name for the model
- `url`: Download URL for the model
- `framework`: Target framework for the model
- `estimatedSize`: Estimated memory usage (optional)

**Returns:**
- `ModelInfo`: The created model info

## Configuration

### Configuration

Main configuration class for the SDK.

#### Constructor

```kotlin
Configuration(
    apiKey: String,
    enableRealTimeDashboard: Boolean = true,
    telemetryConsent: TelemetryConsent = TelemetryConsent.GRANTED
)
```

#### Properties

- `apiKey: String` - API key for authentication
- `baseURL: URL` - Base URL for API requests
- `enableRealTimeDashboard: Boolean` - Enable real-time dashboard updates
- `routingPolicy: RoutingPolicy` - Routing policy for model selection
- `telemetryConsent: TelemetryConsent` - Telemetry consent
- `privacyMode: PrivacyMode` - Privacy mode settings
- `debugMode: Boolean` - Debug mode flag
- `preferredFrameworks: List<LLMFramework>` - Preferred frameworks
- `hardwarePreferences: HardwareConfiguration?` - Hardware preferences
- `modelProviders: List<ModelProviderConfig>` - Model provider configurations
- `memoryThreshold: Long` - Memory threshold for model loading
- `downloadConfiguration: DownloadConfig` - Download configuration

### DownloadConfig

Download configuration settings.

#### Properties

- `maxConcurrentDownloads: Int` - Maximum concurrent downloads
- `retryAttempts: Int` - Number of retry attempts
- `cacheDirectory: File?` - Custom cache directory
- `timeoutInterval: Long` - Download timeout in seconds

### ModelProviderConfig

Model provider configuration.

#### Properties

- `provider: String` - Provider name
- `credentials: ProviderCredentials?` - Authentication credentials
- `enabled: Boolean` - Whether this provider is enabled

### PrivacyMode

Privacy mode settings.

#### Values

- `STANDARD` - Standard privacy protection
- `STRICT` - Enhanced privacy with stricter PII detection
- `CUSTOM` - Custom privacy rules

### RoutingPolicy

Routing policy for model selection.

#### Values

- `AUTOMATIC` - Automatic routing based on device capabilities
- `ON_DEVICE_ONLY` - Always prefer on-device execution
- `CLOUD_ONLY` - Always prefer cloud execution
- `HYBRID` - Hybrid routing with fallback

### TelemetryConsent

Telemetry consent preference.

#### Values

- `GRANTED` - Telemetry is granted
- `DENIED` - Telemetry is denied
- `NOT_DETERMINED` - Telemetry consent not yet determined

## Models

### ModelInfo

Information about a model.

#### Properties

- `id: String` - Unique model identifier
- `name: String` - Display name
- `format: ModelFormat` - Model format
- `downloadURL: URL?` - Download URL
- `localPath: File?` - Local file path
- `estimatedMemory: Long` - Estimated memory usage
- `contextLength: Int` - Context window size
- `downloadSize: Long?` - Download size
- `checksum: String?` - File checksum
- `compatibleFrameworks: List<LLMFramework>` - Compatible frameworks
- `preferredFramework: LLMFramework?` - Preferred framework
- `hardwareRequirements: List<HardwareRequirement>` - Hardware requirements
- `tokenizerFormat: TokenizerFormat?` - Tokenizer format
- `metadata: ModelInfoMetadata?` - Model metadata
- `alternativeDownloadURLs: List<URL>?` - Alternative download URLs
- `additionalProperties: Map<String, Any>` - Additional properties

### LLMFramework

Supported LLM frameworks.

#### Values

- `TENSORFLOW_LITE` - TensorFlow Lite
- `ONNX` - ONNX Runtime
- `EXECUTORCH` - ExecuTorch
- `LLAMACPP` - llama.cpp
- `FOUNDATION_MODELS` - Foundation Models
- `PICOLLM` - Pico LLM
- `MLC` - MLC
- `MEDIAPIPE` - MediaPipe
- `NCNN` - NCNN
- `OPENVINO` - OpenVINO
- `TFLITE_GPU` - TensorFlow Lite GPU
- `TFLITE_NNAPI` - TensorFlow Lite NNAPI

### ModelFormat

Supported model formats.

#### Values

- `TFLITE` - TensorFlow Lite
- `ONNX` - ONNX
- `ORT` - ONNX Runtime
- `SAFETENSORS` - SafeTensors
- `GGUF` - GGUF
- `GGML` - GGML
- `PTE` - ExecuTorch
- `BIN` - Binary
- `WEIGHTS` - Weights
- `CHECKPOINT` - Checkpoint
- `UNKNOWN` - Unknown format

### ExecutionTarget

Execution target for model inference.

#### Values

- `ON_DEVICE` - Execute on device
- `CLOUD` - Execute in the cloud
- `HYBRID` - Hybrid execution

### HardwareAcceleration

Hardware acceleration options.

#### Values

- `CPU` - CPU execution
- `GPU` - GPU acceleration
- `NPU` - NPU acceleration
- `NNAPI` - NNAPI acceleration
- `OPENCL` - OpenCL acceleration
- `VULKAN` - Vulkan acceleration
- `AUTO` - Automatic selection

### HardwareConfiguration

Hardware configuration for framework adapters.

#### Properties

- `primaryAccelerator: HardwareAcceleration` - Primary accelerator
- `fallbackAccelerator: HardwareAcceleration?` - Fallback accelerator
- `memoryMode: MemoryMode` - Memory mode
- `threadCount: Int` - Number of threads
- `useQuantization: Boolean` - Use quantization
- `quantizationBits: Int` - Quantization bits

#### MemoryMode

- `CONSERVATIVE` - Conservative memory usage
- `BALANCED` - Balanced memory usage
- `AGGRESSIVE` - Aggressive memory usage

## Generation

### GenerationOptions

Options for text generation.

#### Properties

- `maxTokens: Int` - Maximum number of tokens to generate
- `temperature: Float` - Temperature for sampling (0.0 - 1.0)
- `topP: Float` - Top-p sampling parameter
- `context: Context?` - Context for the generation
- `enableRealTimeTracking: Boolean` - Enable real-time tracking
- `stopSequences: List<String>` - Stop sequences
- `seed: Int?` - Seed for reproducible generation
- `streamingEnabled: Boolean` - Enable streaming mode
- `tokenBudget: TokenBudget?` - Token budget constraint
- `frameworkOptions: FrameworkOptions?` - Framework-specific options
- `preferredExecutionTarget: ExecutionTarget?` - Preferred execution target

### Context

Context for maintaining conversation state.

#### Properties

- `messages: List<Message>` - Previous messages
- `systemPrompt: String?` - System prompt override
- `maxTokens: Int` - Maximum context window size

### Message

Message in a conversation.

#### Properties

- `role: Role` - Role of the message sender
- `content: String` - Content of the message
- `timestamp: Long` - Timestamp

#### Role

- `USER` - User message
- `ASSISTANT` - Assistant message
- `SYSTEM` - System message

### GenerationResult

Result of a text generation request.

#### Properties

- `text: String` - Generated text
- `tokensUsed: Int` - Number of tokens used
- `modelUsed: String` - Model used for generation
- `latencyMs: Long` - Latency in milliseconds
- `executionTarget: ExecutionTarget` - Execution target
- `savedAmount: Double` - Amount saved by using on-device execution
- `framework: LLMFramework?` - Framework used for generation
- `hardwareUsed: HardwareAcceleration` - Hardware acceleration used
- `memoryUsed: Long` - Memory used during generation
- `tokenizerFormat: TokenizerFormat?` - Tokenizer format used
- `performanceMetrics: PerformanceMetrics` - Detailed performance metrics
- `metadata: ResultMetadata?` - Additional metadata

### DownloadTask

Download task for model downloads.

#### Properties

- `id: String` - Download task ID
- `modelId: String` - Model ID
- `status: DownloadStatus` - Download status
- `progress: Flow<DownloadProgress>` - Download progress flow
- `cancel: () -> Unit` - Cancel function

### DownloadStatus

Download status.

#### Values

- `PENDING` - Download pending
- `DOWNLOADING` - Download in progress
- `COMPLETED` - Download completed
- `FAILED` - Download failed
- `CANCELLED` - Download cancelled

### DownloadProgress

Download progress information.

#### Properties

- `bytesDownloaded: Long` - Bytes downloaded
- `totalBytes: Long` - Total bytes
- `percentage: Float` - Download percentage
- `speed: Long` - Download speed (bytes per second)
- `estimatedTimeRemaining: Long?` - Estimated time remaining (milliseconds)

## Framework Management

### FrameworkAdapter

Framework adapter interface.

#### Methods

- `isAvailable(): Boolean` - Check if framework is available
- `loadModel(modelInfo: ModelInfo): LoadedModel` - Load a model
- `unloadModel(modelId: String)` - Unload a model
- `generate(prompt: String, options: GenerationOptions): GenerationResult` - Generate text
- `generateStream(prompt: String, options: GenerationOptions): Flow<String>` - Generate text stream
- `getSupportedFormats(): List<ModelFormat>` - Get supported formats
- `getHardwareRequirements(): List<HardwareRequirement>` - Get hardware requirements
- `getPerformanceCharacteristics(): PerformanceCharacteristics` - Get performance characteristics

### FrameworkAvailability

Detailed information about framework availability.

#### Properties

- `framework: LLMFramework` - The framework
- `isAvailable: Boolean` - Whether framework is available
- `unavailabilityReason: String?` - Reason for unavailability
- `requirements: List<HardwareRequirement>` - Hardware requirements
- `recommendedFor: List<String>` - Recommended use cases
- `supportedFormats: List<ModelFormat>` - Supported formats

### PerformanceCharacteristics

Performance characteristics for a framework.

#### Properties

- `maxTokensPerSecond: Double` - Maximum tokens per second
- `memoryEfficiency: Double` - Memory efficiency (0.0 to 1.0)
- `batteryEfficiency: Double` - Battery efficiency (0.0 to 1.0)
- `latency: Long` - Latency in milliseconds

## Error Handling

### RunAnywhereError

Main public error type for the RunAnywhere SDK.

#### Error Types

**Initialization Errors:**
- `NotInitialized` - SDK is not initialized
- `AlreadyInitialized` - SDK is already initialized
- `InvalidConfiguration(detail: String)` - Invalid configuration
- `InvalidAPIKey` - Invalid or missing API key

**Model Errors:**
- `ModelNotFound(identifier: String)` - Model not found
- `ModelLoadFailed(identifier: String, error: Throwable?)` - Model load failed
- `ModelValidationFailed(identifier: String, errors: List<ValidationError>)` - Model validation failed
- `ModelIncompatible(identifier: String, reason: String)` - Model incompatible

**Generation Errors:**
- `GenerationFailed(reason: String)` - Generation failed
- `GenerationTimeout` - Generation timed out
- `ContextTooLong(provided: Int, maximum: Int)` - Context too long
- `TokenLimitExceeded(requested: Int, maximum: Int)` - Token limit exceeded
- `CostLimitExceeded(estimated: Double, limit: Double)` - Cost limit exceeded

**Network Errors:**
- `NetworkUnavailable` - Network connection unavailable
- `RequestFailed(error: Throwable)` - Request failed
- `DownloadFailed(url: String, error: Throwable?)` - Download failed

**Storage Errors:**
- `InsufficientStorage(required: Long, available: Long)` - Insufficient storage
- `StorageFull` - Device storage is full

**Hardware Errors:**
- `HardwareUnsupported(feature: String)` - Hardware does not support feature
- `MemoryPressure` - System is under memory pressure
- `ThermalStateExceeded` - Device temperature too high

**Feature Errors:**
- `FeatureNotAvailable(feature: String)` - Feature not available
- `NotImplemented(feature: String)` - Feature not yet implemented

### SDKError

SDK-specific errors.

#### Error Types

- `NotInitialized` - SDK not initialized
- `NotImplemented` - Feature not implemented
- `ModelNotFound(model: String)` - Model not found
- `LoadingFailed(reason: String)` - Loading failed
- `GenerationFailed(reason: String)` - Generation failed
- `FrameworkNotAvailable(framework: String)` - Framework not available
- `DownloadFailed(error: Throwable)` - Download failed
- `ValidationFailed(error: ValidationError)` - Validation failed
- `RoutingFailed(reason: String)` - Routing failed

### ValidationError

Validation error.

#### Properties

- `field: String` - Field name
- `message: String` - Error message
- `code: String?` - Error code

## Services

### ServiceContainer

Service container for dependency injection.

#### Properties

- `configurationValidator: ConfigurationValidator` - Configuration validator
- `modelRegistry: ModelRegistry` - Model registry
- `modelLoadingService: ModelLoadingService` - Model loading service
- `generationService: GenerationService` - Generation service
- `streamingService: StreamingService` - Streaming service
- `downloadService: DownloadService` - Download service
- `fileManager: SimplifiedFileManager` - File manager
- `adapterRegistry: AdapterRegistry` - Adapter registry
- `performanceMonitor: PerformanceMonitor` - Performance monitor
- `benchmarkRunner: BenchmarkRunner` - Benchmark runner
- `abTestRunner: ABTestRunner` - A/B test runner

#### Methods

- `bootstrap(configuration: Configuration)` - Bootstrap all services

### ModelMetadataStore

Model metadata store for persistence.

#### Methods

- `updateLastUsed(modelId: String)` - Update last used timestamp
- `loadStoredModels(): List<ModelInfo>` - Load stored models

### ModelCriteria

Criteria for filtering models.

#### Properties

- `framework: LLMFramework?` - Framework filter
- `format: ModelFormat?` - Format filter
- `maxMemory: Long?` - Maximum memory filter
- `minContextLength: Int?` - Minimum context length filter
- `tags: List<String>` - Tags filter
- `downloaded: Boolean?` - Downloaded filter 