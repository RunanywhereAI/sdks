# RunAnywhere Android SDK

RunAnywhere is a powerful Android SDK that enables intelligent AI model execution with automatic routing between on-device and cloud models. It optimizes for cost, privacy, and performance while providing a unified interface for various AI model formats.

## Features

- =€ **Intelligent Routing**: Automatically decides between on-device and cloud execution based on device capabilities, model requirements, and user preferences
- = **Privacy-First**: Prioritizes on-device execution for sensitive data with configurable privacy policies
- =° **Cost Optimization**: Real-time cost tracking and savings calculations
- <¯ **Multi-Format Support**: Seamlessly works with GGUF, ONNX, TensorFlow Lite, and other popular formats
- =ñ **Android-Optimized**: Built with Kotlin coroutines and Android best practices
- = **Automatic Model Management**: Handles model downloading, caching, and memory management
- =Ê **Performance Monitoring**: Built-in metrics for latency, token throughput, and resource usage
- =á **Security Built-in**: Secure API key storage, credential scanning, and runtime security checks

## Requirements

- Android SDK 24+ (Android 7.0+)
- Kotlin 2.0.21+
- Gradle 8.11.1+
- Java 11+

## Installation

### Gradle (Kotlin DSL)

Add RunAnywhere to your app's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.runanywhere:runanywhere-android:1.0.0")
}
```

### Gradle (Groovy)

Add RunAnywhere to your app's `build.gradle`:

```groovy
dependencies {
    implementation 'com.runanywhere:runanywhere-android:1.0.0'
}
```

### Maven

```xml
<dependency>
    <groupId>com.runanywhere</groupId>
    <artifactId>runanywhere-android</artifactId>
    <version>1.0.0</version>
</dependency>
```

## Quick Start

### 1. Add Permissions

Add required permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 2. Initialize the SDK

```kotlin
import com.runanywhere.sdk.RunAnywhereSDK
import com.runanywhere.sdk.configuration.Configuration

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize the SDK
        val sdk = RunAnywhereSDK.shared
        val configuration = Configuration(
            apiKey = "your-api-key",
            enableRealTimeDashboard = true,
            telemetryConsent = TelemetryConsent.GRANTED
        )

        lifecycleScope.launch {
            sdk.initialize(configuration)
        }
    }
}
```

### 3. Load a Model

```kotlin
// Load a model by name
val model = sdk.loadModel("llama-3.2-1b")

// Or check available models first
val availableModels = sdk.listAvailableModels()
println("Available models: ${availableModels.map { it.name }}")
```

### 4. Generate Text

```kotlin
// Simple generation
val result = sdk.generate(
    prompt = "Explain quantum computing in simple terms",
    options = GenerationOptions(
        maxTokens = 100,
        temperature = 0.7f
    )
)

println(result.text)
println("Cost: $${result.costBreakdown.totalCost}")
println("Saved: $${result.savedAmount}")
println("Execution: ${result.executionTarget}")
```

### 5. Chat Conversations

```kotlin
// Create a conversation context
val context = Context().apply {
    addMessage(Message(Role.USER, "What is Kotlin?"))
    addMessage(Message(Role.ASSISTANT, "Kotlin is a modern programming language..."))
    addMessage(Message(Role.USER, "What are its main features?"))
}

// Generate with context
val result = sdk.generate(
    prompt = "Please answer based on our conversation",
    context = context,
    options = GenerationOptions(maxTokens = 200)
)
```

## Security Features

### Secure API Key Storage

```kotlin
// API keys are automatically encrypted and stored securely
val secureStorage = SecureStorage(context)

// Store API key securely
secureStorage.storeAPIKey("your-api-key")

// Retrieve API key
val apiKey = secureStorage.retrieveAPIKey()
```

### Security Configuration

```kotlin
// Use strict security for production
val config = Configuration(apiKey = apiKey)
config.securityConfiguration = SecurityConfiguration.strict()

// Or customize security settings
config.securityConfiguration = SecurityConfiguration(
    validateAPIKey = true,
    minimumAPIKeyLength = 64,
    scanLogsForCredentials = true,
    useSecureStorage = true,
    enableRuntimeSecurityChecks = true,
    redactSensitiveErrors = true
)
```

## Basic Usage Examples

### Privacy-Focused Generation

```kotlin
// Configure for maximum privacy
val configuration = Configuration(
    apiKey = apiKey,
    privacyMode = PrivacyMode.STRICT,
    routingPolicy = RoutingPolicy.ON_DEVICE_ONLY
)

sdk.initialize(configuration)

// All generation will happen on-device
val result = sdk.generate(
    prompt = "Process this sensitive data...",
    options = GenerationOptions(maxTokens = 100)
)
```

### Cost-Optimized Generation

```kotlin
// Configure for cost optimization
val options = GenerationOptions(
    maxTokens = 100,
    temperature = 0.7f,
    routingPolicy = RoutingPolicy.COST_OPTIMIZED,
    maxCostPerGeneration = 0.001  // $0.001 limit
)

val result = sdk.generate(prompt, options)

println("Actual cost: $${result.costBreakdown.totalCost}")
println("Saved: $${result.savedAmount}")
println("Execution target: ${result.executionTarget}")
```

### Streaming Responses

```kotlin
// Stream tokens as they're generated
val stream = sdk.generateStream(
    prompt = "Write a story about a robot",
    options = GenerationOptions(maxTokens = 500)
)

stream.collect { chunk ->
    print(chunk)
}
```

### Background Processing

```kotlin
// Use WorkManager for background generation
class TextGenerationWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val prompt = inputData.getString("prompt") ?: return Result.failure()

        val sdk = RunAnywhereSDK.shared
        val result = sdk.generate(prompt)

        // Save result
        val outputData = workDataOf(
            "generated_text" to result.text,
            "cost" to result.costBreakdown.totalCost
        )

        return Result.success(outputData)
    }
}
```

## Model Support

RunAnywhere supports various model formats optimized for Android:

| Format | Description | Hardware Acceleration |
|--------|-------------|----------------------|
| **GGUF** | Llama, Mistral, and other popular models | CPU optimized |
| **TensorFlow Lite** | Optimized TensorFlow models | GPU, NNAPI |
| **ONNX** | Cross-platform neural network models | CPU, GPU |
| **MediaPipe** | Google's on-device ML solutions | GPU, NPU |

### Registering Custom Framework Adapters

```kotlin
// Register a custom framework adapter
val customAdapter = MyCustomFrameworkAdapter()
sdk.registerFrameworkAdapter(customAdapter)

// Check available frameworks
val frameworks = sdk.getAvailableFrameworks()
println("Available frameworks: $frameworks")
```

## Error Handling

```kotlin
try {
    val result = sdk.generate(
        prompt = "Hello",
        options = GenerationOptions()
    )
    println(result.text)
} catch (e: RunAnywhereError) {
    when (e) {
        is SDKError.ModelNotFound -> {
            println("Model not found: ${e.message}")
        }
        is SDKError.InsufficientMemory -> {
            println("Not enough memory")
        }
        is SDKError.NetworkError -> {
            println("Network error: ${e.cause}")
        }
        is SDKError.Unauthorized -> {
            println("Invalid API key")
        }
        else -> {
            println("Error: $e")
        }
    }
}
```

## Performance Monitoring

```kotlin
// Enable performance monitoring
val monitor = sdk.performanceMonitor
monitor.startMonitoring()

// Generate with monitoring
val result = sdk.generate(prompt, options)

// Access performance metrics
println("Inference time: ${result.performanceMetrics.inferenceTime}ms")
println("Tokens/second: ${result.performanceMetrics.tokensPerSecond}")
println("Memory peak: ${result.performanceMetrics.memoryPeak} bytes")
println("CPU usage: ${result.performanceMetrics.cpuUsage}%")

// Get aggregated metrics
val report = monitor.getPerformanceReport()
```

## ProGuard Rules

If you're using ProGuard or R8, add these rules to your `proguard-rules.pro`:

```proguard
-keep class com.runanywhere.sdk.** { *; }
-keep interface com.runanywhere.sdk.** { *; }

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# OkHttp/Retrofit
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
```

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/RunanywhereAI/runanywhere-android
cd runanywhere-android

# Build the SDK
./gradlew build

# Run tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Generate AAR
./gradlew assembleRelease
```

### Running Tests

```bash
# Run unit tests
./gradlew test

# Run with coverage
./gradlew testDebugUnitTestCoverage

# Run specific test
./gradlew test --tests "com.runanywhere.sdk.GenerationTest"
```

### Linting

```bash
# Run Android Lint
./gradlew lint

# Run detekt for Kotlin analysis
./gradlew detekt
```

## Documentation

- [Architecture Overview](../../docs/ARCHITECTURE.md) - Detailed SDK architecture and design
- [API Reference](API_REFERENCE.md) - Complete API documentation
- [Security Guidelines](../../SECURITY.md) - Security best practices
- [Examples](../../examples/android/) - Sample applications and code snippets

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](../../CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and ensure they pass
4. Commit your changes (`git commit -m 'feat: add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../../LICENSE) file for details.

## Support

- =ç Email: [support@runanywhere.ai](mailto:support@runanywhere.ai)
- =¬ Discord: [Join our community](https://discord.gg/runanywhere)
- =Ú Documentation: [docs.runanywhere.ai](https://docs.runanywhere.ai)
- = Issues: [GitHub Issues](https://github.com/RunanywhereAI/runanywhere-android/issues)

## Acknowledgments

Built with d by the RunAnywhere team. Special thanks to all our contributors and the open-source community.
