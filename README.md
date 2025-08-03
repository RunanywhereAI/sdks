# RunAnywhere SDKs

<p align="center">
  <img src="examples/logo.svg" alt="RunAnywhere Logo" width="200"/>
</p>

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Android SDK CI](https://github.com/RunanywhereAI/runanywhere-sdks/actions/workflows/android-sdk.yml/badge.svg)](https://github.com/RunanywhereAI/runanywhere-sdks/actions/workflows/android-sdk.yml)
[![iOS SDK CI](https://github.com/RunanywhereAI/runanywhere-sdks/actions/workflows/ios-sdk.yml/badge.svg)](https://github.com/RunanywhereAI/runanywhere-sdks/actions/workflows/ios-sdk.yml)
[![Security Scan](https://img.shields.io/badge/Security-Gitleaks-green.svg)](https://github.com/gitleaks/gitleaks)

Cross-platform SDKs for the RunAnywhere on-device AI platform. RunAnywhere provides intelligent routing between on-device and cloud AI models to optimize for cost, privacy, and performance.

## 🏗️ Repository Components

This repository contains four main components:

### 📱 SDKs
- **[Android SDK](sdk/runanywhere-android/)** - Kotlin-based SDK for Android applications
- **[iOS SDK](sdk/runanywhere-swift/)** - Swift Package Manager-based SDK for iOS/macOS/tvOS/watchOS

### 🚀 Sample Applications
- **[Android Demo App](examples/android/RunAnywhereAI/)** - Sample Android app demonstrating SDK usage
- **[iOS Demo App](examples/ios/RunAnywhereAI/)** - Sample iOS app demonstrating SDK usage

## ✨ Key Features

- **🤖 Intelligent Routing**: Automatically decides between on-device and cloud AI models
- **💰 Cost Optimization**: Real-time cost and savings tracking
- **🔒 Privacy-First**: Keep sensitive data on-device when possible
- **🔄 Universal Model Support**: GGUF, ONNX, Core ML, MLX, TensorFlow Lite
- **⚡ Modern APIs**: Async/await patterns with Kotlin coroutines and Swift concurrency
- **📊 Performance Metrics**: Detailed execution statistics and model performance data
- **🛡️ Security Built-in**: Credential scanning, secure storage, and API key validation

## 🚀 Quick Start

### Android SDK

Add to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.runanywhere:runanywhere-android:1.0.0")
}
```

Initialize and use:

```kotlin
// Initialize the SDK
val sdk = RunAnywhereSDK.shared
val config = Configuration(
    apiKey = "your-api-key",
    enableRealTimeDashboard = true
)
sdk.initialize(config)

// Load a model
val model = sdk.loadModel("llama-3.2-1b")

// Generate text
val options = GenerationOptions(
    maxTokens = 100,
    temperature = 0.7f
)

val result = sdk.generate("Hello, world!", options)
println("Generated: ${result.text}")
println("Cost: $${result.costBreakdown.totalCost}")
println("Saved: $${result.savedAmount}")
```

### iOS SDK

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RunanywhereAI/runanywhere-swift.git", from: "1.0.0")
]
```

Initialize and use:

```swift
// Initialize the SDK
let sdk = RunAnywhereSDK.shared
let config = Configuration(
    apiKey: "your-api-key",
    enableRealTimeDashboard: true
)
await sdk.initialize(configuration: config)

// Load a model
let model = try await sdk.loadModel("llama-3.2-1b")

// Generate text
let options = GenerationOptions(
    maxTokens: 100,
    temperature: 0.7
)

let result = try await sdk.generate(
    prompt: "Hello, world!",
    options: options
)
print("Generated: \(result.text)")
print("Cost: $\(result.costBreakdown.totalCost)")
print("Saved: $\(result.savedAmount)")
```

## 📋 Requirements

### Android SDK
- **Minimum SDK**: 24 (Android 7.0)
- **Target SDK**: 36
- **Kotlin**: 2.0.21+
- **Gradle**: 8.11.1+
- **Java**: 11+

### iOS SDK
- **iOS**: 13.0+ / **macOS**: 10.15+ / **tvOS**: 13.0+ / **watchOS**: 6.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+

## 🔒 Security

### Built-in Security Features

- **🔑 API Key Validation**: Minimum length and pattern checks
- **🔐 Secure Storage**: Keychain integration on iOS, encrypted preferences on Android
- **🚫 Credential Scanning**: Automatic detection and blocking of exposed secrets
- **📝 Log Redaction**: Automatic removal of sensitive data from logs
- **🔏 Certificate Pinning**: Optional SSL certificate validation
- **🛡️ Runtime Checks**: Debugger and jailbreak/root detection

### Security Best Practices

1. **Never commit API keys** - Store them in environment variables or secure configuration
2. **Use the provided secure storage** - Don't store credentials in plain text
3. **Enable security configuration** - Use `SecurityConfiguration.strict` for production
4. **Rotate API keys regularly** - The SDK will warn about old keys

## 🛠️ Development Setup

### Prerequisites

1. Install development tools:
```bash
# macOS
brew install pre-commit gitleaks swiftlint

# Install Java for Android development
brew install openjdk@17
```

2. Set up pre-commit hooks:
```bash
pre-commit install
```

### Building the Android SDK

```bash
cd sdk/runanywhere-android/
./gradlew build
./gradlew test
./gradlew lint
```

### Building the iOS SDK

```bash
cd sdk/runanywhere-swift/
swift build
swift test
swiftlint
```

### Running Example Apps

#### Android Example
```bash
cd examples/android/RunAnywhereAI/
./gradlew installDebug
```

#### iOS Example
```bash
cd examples/ios/RunAnywhereAI/
./scripts/build_and_run.sh simulator "iPhone 16 Pro"
```

## 🧪 Testing

Both SDKs include comprehensive test suites:

```bash
# Android
./gradlew test
./gradlew connectedAndroidTest

# iOS
swift test --enable-code-coverage
```

## 🔍 Code Quality & Security

### Pre-commit Hooks

Our pre-commit hooks ensure code quality and security:

- **Gitleaks**: Scans for exposed credentials
- **Security Check**: Additional credential pattern detection
- **TODO Policy**: Enforces GitHub issue references
- **Linting**: SwiftLint for iOS, Android Lint for Android

### Running Checks Manually

```bash
# Security scan
gitleaks detect --config .gitleaks.toml

# Run all pre-commit hooks
pre-commit run --all-files

# Lint checks
./scripts/lint-all.sh
```

### TODO Policy

All TODO-style comments must reference a GitHub issue:
- ✅ Correct: `// TODO: #123 - Implement error handling`
- ❌ Wrong: `// TODO: Implement error handling`

## 📖 Documentation

- [Android SDK Documentation](sdk/runanywhere-android/README.md)
- [iOS SDK Documentation](sdk/runanywhere-swift/README.md)
- [API Reference](docs/API_REFERENCE.md)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [Security Policy](SECURITY.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code of conduct
- Development setup
- Submitting pull requests
- Reporting issues
- Security vulnerability reporting

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🏢 About RunAnywhere

RunAnywhere is building the future of on-device AI, providing developers with intelligent routing capabilities that balance cost, privacy, and performance. Our platform automatically decides when to run AI models locally versus in the cloud, optimizing for your specific use case.

### Links

- 🌐 [Website](https://runanywhere.ai)
- 📚 [Documentation](https://docs.runanywhere.ai)
- 💬 [Discord Community](https://discord.gg/runanywhere)
- 🐦 [Twitter](https://twitter.com/runanywhereai)

---

**Questions?** Feel free to [open an issue](https://github.com/RunanywhereAI/runanywhere-sdks/issues) or reach out to our team.
