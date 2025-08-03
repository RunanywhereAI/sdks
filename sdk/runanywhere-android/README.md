# RunAnywhere Android SDK

The RunAnywhere Android SDK provides a comprehensive solution for running Large Language Models (LLMs) on Android devices. It supports multiple frameworks, offers intelligent routing between on-device and cloud execution, and provides cost optimization features.

## Features

### Core Functionality
- **Multi-Framework Support**: TensorFlow Lite, ONNX Runtime, ExecuTorch, llama.cpp, and more
- **Intelligent Routing**: Automatic selection between on-device and cloud execution
- **Cost Optimization**: Real-time cost tracking and savings calculation
- **Model Management**: Download, load, and manage models locally
- **Streaming Generation**: Real-time text generation with streaming support

### Advanced Features
- **Performance Monitoring**: Real-time performance metrics and monitoring
- **A/B Testing**: Framework and model comparison capabilities
- **Benchmarking**: Comprehensive benchmarking suite
- **Hardware Acceleration**: Support for GPU, NPU, and NNAPI acceleration
- **Memory Management**: Intelligent memory allocation and optimization

## Installation

Add the following to your `build.gradle` file:

```gradle
dependencies {
    implementation 'com.runanywhere:sdk:1.0.0'
}
```

## Quick Start

### 1. Initialize the SDK

```kotlin
import com.runanywhere.sdk.RunAnywhereSDK
import com.runanywhere.sdk.configuration.Configuration

// Initialize with your API key
val configuration = Configuration(
    apiKey = "your-api-key-here",
    enableRealTimeDashboard = true
)

// Initialize the SDK
RunAnywhereSDK.shared.initialize(configuration)
```

### 2. Load a Model

```kotlin
// Load a model by identifier
val modelInfo = RunAnywhereSDK.shared.loadModel("gpt-2-small")
```

### 3. Generate Text

```kotlin
// Generate text with default options
val result = RunAnywhereSDK.shared.generate("Hello, how are you?")

// Or with custom options
val options = GenerationOptions(
    maxTokens = 100,
    temperature = 0.7f,
    topP = 1.0f
)
val result = RunAnywhereSDK.shared.generate("Hello, how are you?", options)
```

### 4. Streaming Generation

```kotlin
// Generate text as a stream
val stream = RunAnywhereSDK.shared.generateStream("Tell me a story")
stream.collect { chunk ->
    println(chunk) // Print each chunk as it's generated
}
```

## Configuration

### Basic Configuration

```kotlin
val configuration = Configuration(
    apiKey = "your-api-key",
    enableRealTimeDashboard = true,
    telemetryConsent = TelemetryConsent.GRANTED
)
```

### Advanced Configuration

```kotlin
val configuration = Configuration(
    apiKey = "your-api-key",
    enableRealTimeDashboard = true,
    routingPolicy = RoutingPolicy.AUTOMATIC,
    privacyMode = PrivacyMode.STANDARD,
    debugMode = false,
    preferredFrameworks = listOf(LLMFramework.TENSORFLOW_LITE, LLMFramework.ONNX),
    hardwarePreferences = HardwareConfiguration(
        primaryAccelerator = HardwareAcceleration.GPU,
        fallbackAccelerator = HardwareAcceleration.CPU,
        memoryMode = HardwareConfiguration.MemoryMode.BALANCED,
        threadCount = 4
    ),
    memoryThreshold = 500_000_000, // 500MB
    downloadConfiguration = DownloadConfig(
        maxConcurrentDownloads = 2,
        retryAttempts = 3,
        timeoutInterval = 300
    )
)
```

## Model Management

### List Available Models

```kotlin
val models = RunAnywhereSDK.shared.listAvailableModels()
models.forEach { model ->
    println("Model: ${model.name}, Format: ${model.format}")
}
```

### Download a Model

```kotlin
val downloadTask = RunAnywhereSDK.shared.downloadModel("gpt-2-small")
downloadTask.progress.collect { progress ->
    println("Download progress: ${progress.percentage}%")
}
```

### Add Custom Model

```kotlin
val modelInfo = RunAnywhereSDK.shared.addModelFromURL(
    name = "My Custom Model",
    url = "https://example.com/model.tflite",
    framework = LLMFramework.TENSORFLOW_LITE,
    estimatedSize = 100_000_000 // 100MB
)
```

### Delete a Model

```kotlin
RunAnywhereSDK.shared.deleteModel("gpt-2-small")
```

## Framework Management

### Register Framework Adapters

```kotlin
// Register a custom framework adapter
val adapter = MyCustomFrameworkAdapter()
RunAnywhereSDK.shared.registerFrameworkAdapter(adapter)
```

### Check Framework Availability

```kotlin
val frameworks = RunAnywhereSDK.shared.getAvailableFrameworks()
val availability = RunAnywhereSDK.shared.getFrameworkAvailability()

availability.forEach { info ->
    println("${info.framework.displayName}: ${if (info.isAvailable) "Available" else "Not Available"}")
}
```

### Get Models for Specific Framework

```kotlin
val tensorFlowModels = RunAnywhereSDK.shared.getModelsForFramework(LLMFramework.TENSORFLOW_LITE)
```

## Advanced Features

### Performance Monitoring

```kotlin
val monitor = RunAnywhereSDK.shared.performanceMonitor
// Access performance metrics and monitoring capabilities
```

### Benchmarking

```kotlin
val benchmark = RunAnywhereSDK.shared.benchmarkSuite
// Run benchmarks and compare performance
```

### A/B Testing

```kotlin
val abTesting = RunAnywhereSDK.shared.abTesting
// Run A/B tests between different frameworks or models
```

### File Management

```kotlin
val fileManager = RunAnywhereSDK.shared.fileManager
// Access file management capabilities
```

## Error Handling

The SDK provides comprehensive error handling with specific error types:

```kotlin
try {
    val result = RunAnywhereSDK.shared.generate("Hello")
} catch (e: RunAnywhereError) {
    when (e) {
        is RunAnywhereError.NotInitialized -> {
            // Handle not initialized error
        }
        is RunAnywhereError.ModelNotFound -> {
            // Handle model not found error
        }
        is RunAnywhereError.GenerationFailed -> {
            // Handle generation failed error
        }
        // ... handle other error types
    }
}
```

## Supported Frameworks

- **TensorFlow Lite**: Optimized for mobile and embedded devices
- **ONNX Runtime**: Cross-platform inference engine
- **ExecuTorch**: PyTorch-based mobile inference
- **llama.cpp**: Efficient C++ implementation for LLaMA models
- **Foundation Models**: Apple's framework for on-device ML
- **Pico LLM**: Lightweight LLM framework
- **MLC**: Machine Learning Compilation framework
- **MediaPipe**: Google's ML framework
- **NCNN**: Tencent's neural network inference framework
- **OpenVINO**: Intel's deep learning toolkit

## Model Formats

- **TensorFlow Lite (.tflite)**
- **ONNX (.onnx)**
- **SafeTensors (.safetensors)**
- **GGUF (.gguf)**
- **GGML (.ggml)**
- **ExecuTorch (.pte)**
- **Binary (.bin)**
- **Weights (.weights)**
- **Checkpoint (.checkpoint)**

## Hardware Acceleration

The SDK supports various hardware acceleration options:

- **CPU**: Standard CPU execution
- **GPU**: GPU acceleration when available
- **NPU**: Neural Processing Unit acceleration
- **NNAPI**: Android Neural Networks API
- **OpenCL**: OpenCL-based acceleration
- **Vulkan**: Vulkan-based acceleration

## Privacy and Security

- **On-Device Execution**: Models run locally for enhanced privacy
- **Data Encryption**: Secure handling of sensitive data
- **Privacy Modes**: Configurable privacy protection levels
- **Telemetry Control**: User-controlled telemetry and analytics

## Performance Optimization

- **Memory Management**: Intelligent memory allocation
- **Model Quantization**: Support for quantized models
- **Thread Management**: Optimized thread usage
- **Caching**: Intelligent caching strategies
- **Load Balancing**: Dynamic load distribution

## Troubleshooting

### Common Issues

1. **SDK Not Initialized**
   - Ensure you call `initialize()` before using any SDK methods

2. **Model Not Found**
   - Check if the model is downloaded or available
   - Verify the model identifier

3. **Insufficient Memory**
   - Check available device memory
   - Consider using a smaller model or enabling quantization

4. **Framework Not Available**
   - Ensure the required framework is installed
   - Check device compatibility

### Debug Mode

Enable debug mode for detailed logging:

```kotlin
val configuration = Configuration(
    apiKey = "your-api-key",
    debugMode = true
)
```

## API Reference

For detailed API documentation, see the [API Reference](API_REFERENCE.md).

## Architecture

For information about the SDK architecture, see the [Architecture Guide](ARCHITECTURE.md).

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This SDK is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Email: support@runanywhere.ai
- Documentation: https://docs.runanywhere.ai
- GitHub Issues: https://github.com/runanywhere/sdk-android/issues 