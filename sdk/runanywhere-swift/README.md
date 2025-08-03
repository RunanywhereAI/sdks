# RunAnywhere Swift SDK

RunAnywhere is a powerful Swift SDK that enables intelligent AI model execution with automatic routing between on-device and cloud models. It optimizes for cost, privacy, and performance while providing a unified interface for various AI model formats.

## Features

- 🚀 **Intelligent Routing**: Automatically decides between on-device and cloud execution based on device capabilities, model requirements, and user preferences
- 🔒 **Privacy-First**: Prioritizes on-device execution for sensitive data with configurable privacy policies
- 💰 **Cost Optimization**: Real-time cost tracking and savings calculations
- 🎯 **Multi-Format Support**: Seamlessly works with GGUF, ONNX, Core ML, MLX, and TensorFlow Lite models
- 📱 **Cross-Platform**: Supports iOS 13.0+, macOS 10.15+, tvOS 13.0+, and watchOS 6.0+
- 🔄 **Automatic Model Management**: Handles model downloading, caching, and memory management
- 📊 **Performance Monitoring**: Built-in metrics for latency, token throughput, and resource usage
- 🛡️ **Security Built-in**: Secure API key storage, credential scanning, and runtime security checks

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add RunAnywhere to your project using Swift Package Manager:

1. In Xcode, select **File > Add Package Dependencies**
2. Enter the repository URL: `https://github.com/RunanywhereAI/runanywhere-swift`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RunanywhereAI/runanywhere-swift", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["RunAnywhere"]
    )
]
```

## Quick Start

### 1. Initialize the SDK

```swift
import RunAnywhere

// Initialize with your API key
let configuration = Configuration(
    apiKey: "your-api-key",
    enableRealTimeDashboard: true,
    telemetryConsent: .granted
)

// Configure security settings
configuration.securityConfiguration = .default

try await RunAnywhereSDK.shared.initialize(configuration: configuration)
```

### 2. Load a Model

```swift
// Load a model by name (automatic format detection)
let model = try await RunAnywhereSDK.shared.loadModel("llama-3.2-1b")

// Or check available models first
let availableModels = try await RunAnywhereSDK.shared.listAvailableModels()
print("Available models: \(availableModels.map { $0.name })")
```

### 3. Generate Text

```swift
// Simple generation
let result = try await RunAnywhereSDK.shared.generate(
    prompt: "Explain quantum computing in simple terms",
    options: GenerationOptions(
        maxTokens: 100,
        temperature: 0.7
    )
)

print(result.text)
print("Cost: $\(result.costBreakdown.totalCost)")
print("Saved: $\(result.savedAmount)")
print("Execution: \(result.executionTarget)")
```

### 4. Chat Conversations

```swift
// Create a conversation context
let context = Context()
context.addMessage(Message(role: .user, content: "What is Swift?"))
context.addMessage(Message(role: .assistant, content: "Swift is a modern programming language..."))
context.addMessage(Message(role: .user, content: "What are its main features?"))

// Generate with context
let result = try await RunAnywhereSDK.shared.generate(
    prompt: "Please answer based on our conversation",
    context: context,
    options: GenerationOptions(maxTokens: 200)
)
```

## Security Features

### Secure API Key Storage

```swift
// API keys are automatically stored in the iOS Keychain
let secureStorage = SecureStorage(serviceName: "com.yourapp.runanywhere")

// Store API key securely
try secureStorage.storeAPIKey("your-api-key")

// Retrieve API key
let apiKey = try secureStorage.retrieveAPIKey()
```

### Security Configuration

```swift
// Use strict security for production
let config = Configuration(apiKey: apiKey)
config.securityConfiguration = .strict

// Or customize security settings
config.securityConfiguration = SecurityConfiguration(
    validateAPIKey: true,
    minimumAPIKeyLength: 64,
    scanLogsForCredentials: true,
    useSecureStorage: true,
    enableCertificatePinning: true,
    pinnedCertificates: ["your-cert-fingerprint"],
    enableRuntimeSecurityChecks: true,
    redactSensitiveErrors: true
)
```

### Credential Scanning

The SDK automatically scans and redacts sensitive information from logs:

```swift
// Logs are automatically redacted
// Original: "API Key: sk-1234567890abcdef"
// Logged as: "API Key: sk-12...[API Key REDACTED]"
```

## Basic Usage Examples

### Privacy-Focused Generation

```swift
// Configure for maximum privacy
var configuration = Configuration(apiKey: apiKey)
configuration.privacyMode = .strict
configuration.routingPolicy = .onDeviceOnly

try await RunAnywhereSDK.shared.initialize(configuration: configuration)

// All generation will happen on-device
let result = try await RunAnywhereSDK.shared.generate(
    prompt: "Process this sensitive data...",
    options: GenerationOptions(maxTokens: 100)
)
```

### Cost-Optimized Generation

```swift
// Configure for cost optimization
let options = GenerationOptions(
    maxTokens: 100,
    temperature: 0.7,
    routingPolicy: .costOptimized,
    maxCostPerGeneration: 0.001  // $0.001 limit
)

let result = try await RunAnywhereSDK.shared.generate(
    prompt: prompt,
    options: options
)

print("Actual cost: $\(result.costBreakdown.totalCost)")
print("Saved: $\(result.savedAmount)")
print("Execution target: \(result.executionTarget)")
```

### Streaming Responses

```swift
// Stream tokens as they're generated
let stream = RunAnywhereSDK.shared.generateStream(
    prompt: "Write a story about a robot",
    options: GenerationOptions(maxTokens: 500)
)

for try await chunk in stream {
    print(chunk, terminator: "")
}
```

## Model Support

RunAnywhere supports various model formats out of the box:

| Format | Description | Supported Devices |
|--------|-------------|-------------------|
| **GGUF** | Llama, Mistral, and other popular models | All devices |
| **Core ML** | Apple's optimized format | iOS, macOS |
| **MLX** | Apple's new ML framework | Apple Silicon Macs |
| **ONNX** | Cross-platform neural network models | All devices |
| **TensorFlow Lite** | Lightweight TensorFlow models | All devices |

### Registering Custom Framework Adapters

```swift
// Register a custom framework adapter
let customAdapter = MyCustomFrameworkAdapter()
RunAnywhereSDK.shared.registerFrameworkAdapter(customAdapter)

// Check available frameworks
let frameworks = RunAnywhereSDK.shared.getAvailableFrameworks()
print("Available frameworks: \(frameworks)")
```

## Error Handling

```swift
do {
    let result = try await RunAnywhereSDK.shared.generate(
        prompt: "Hello",
        options: GenerationOptions()
    )
    print(result.text)
} catch let error as RunAnywhereError {
    switch error {
    case .modelNotFound(let message):
        print("Model not found: \(message)")
    case .insufficientMemory(let required, let available):
        print("Need \(required) bytes, have \(available)")
    case .networkError(let underlying):
        print("Network error: \(underlying)")
    case .unauthorized:
        print("Invalid API key")
    default:
        print("Error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Performance Monitoring

```swift
// Enable performance monitoring
let monitor = RunAnywhereSDK.shared.performanceMonitor
monitor.startMonitoring()

// Generate with monitoring
let result = try await RunAnywhereSDK.shared.generate(
    prompt: prompt,
    options: options
)

// Access performance metrics
print("Inference time: \(result.performanceMetrics.inferenceTime)ms")
print("Tokens/second: \(result.performanceMetrics.tokensPerSecond)")
print("Memory peak: \(result.performanceMetrics.memoryPeak) bytes")
print("CPU usage: \(result.performanceMetrics.cpuUsage)%")
```

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/RunanywhereAI/runanywhere-swift
cd runanywhere-swift

# Build the SDK
swift build

# Run tests
swift test

# Run with specific platform
xcodebuild build -scheme RunAnywhere -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running Tests

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter RunAnywhereTests.GenerationTests

# Generate coverage report
swift test --enable-code-coverage
xcrun llvm-cov export \
  .build/debug/RunAnywherePackageTests.xctest/Contents/MacOS/RunAnywherePackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -format=lcov > coverage.lcov
```

### Linting

```bash
# Run SwiftLint
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Documentation

- [Architecture Overview](../../docs/ARCHITECTURE.md) - Detailed SDK architecture and design
- [API Reference](../../docs/API_REFERENCE.md) - Complete API documentation
- [Security Guidelines](../../SECURITY.md) - Security best practices
- [Examples](../../examples/ios/) - Sample applications and code snippets

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

- 📧 Email: [support@runanywhere.ai](mailto:support@runanywhere.ai)
- 💬 Discord: [Join our community](https://discord.gg/runanywhere)
- 📚 Documentation: [docs.runanywhere.ai](https://docs.runanywhere.ai)
- 🐛 Issues: [GitHub Issues](https://github.com/RunanywhereAI/runanywhere-swift/issues)

## Acknowledgments

Built with ❤️ by the RunAnywhere team. Special thanks to all our contributors and the open-source community.
