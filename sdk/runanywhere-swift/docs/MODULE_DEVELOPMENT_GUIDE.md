# Module Development Guide

This guide explains how to create external modules that integrate with the RunAnywhere SDK, following the established patterns from FluidAudioDiarization and SherpaONNXTTS.

## Two Integration Patterns

1. **Self-Contained** (FluidAudioDiarization): Module handles its own resources
2. **SDK-Integrated** (SherpaONNXTTS): Module leverages SDK infrastructure

Choose based on your needs - both are valid approaches.

## Quick Start

```swift
// 1. Import SDK
import RunAnywhereSDK

// 2. Implement service protocol
public class MyModuleService: YourServiceProtocol {
    private let sdk = RunAnywhereSDK.shared

    public init() {
        // Register models, strategies, etc.
    }
}

// 3. Module auto-registers when imported
```

---

## Module Structure

### Directory Layout
```
Modules/YourModule/
├── Package.swift              # SPM package definition
├── Sources/
│   └── YourModule/
│       ├── Public/           # Public API
│       │   └── YourModuleService.swift
│       └── Internal/         # Implementation details
│           ├── Models/
│           ├── Helpers/
│           └── Bridge/
└── Tests/
```

### Package.swift Template
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourModule",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "YourModule", targets: ["YourModule"])
    ],
    dependencies: [
        // Depend on the SDK
        .package(path: "../../"),  // Adjust path as needed
    ],
    targets: [
        .target(
            name: "YourModule",
            dependencies: [
                .product(name: "RunAnywhereSDK", package: "runanywhere-swift")
            ]
        )
    ]
)
```

---

## Step-by-Step Implementation

### 1. Define Your Service

```swift
import RunAnywhereSDK
import Foundation

public class YourModuleService: YourProtocol {
    private let sdk: RunAnywhereSDK

    public init(sdk: RunAnywhereSDK = .shared) {
        self.sdk = sdk
    }

    public func initialize() async throws {
        // Your initialization logic
    }
}
```

### 2. Register Models

```swift
private func registerModels() {
    let models = [
        ModelInfo(
            id: "your-model-v1",
            name: "Your Model",
            framework: .custom("your-framework"),
            format: .onnx,  // or .gguf, .mlmodelc, etc.
            downloadURL: URL(string: "https://example.com/model.bin"),
            downloadSize: 100_000_000,
            estimatedMemoryUsage: 200_000_000
        )
    ]

    sdk.registerModuleModels(models)
}
```

### 3. Use SDK File Management

```swift
// Get framework-specific storage
let storageDir = try sdk.getFrameworkStorageDirectory(for: "your-framework")

// Create module cache
let cacheDir = try sdk.createModuleCache(moduleId: "your-module")

// Clear cache when needed
try sdk.clearModuleCache(moduleId: "your-module")
```

### 4. Implement Download Strategy (Optional)

```swift
public class YourDownloadStrategy: DownloadStrategy {
    public var identifier: String { "your-module-strategy" }

    public func canHandle(model: ModelInfo) -> Bool {
        return model.id.hasPrefix("your-model")
    }

    public func downloadModel(
        _ model: ModelInfo,
        using downloadManager: DownloadManager,
        to destination: URL
    ) async throws -> DownloadTask {
        // Custom download logic if needed
        return try await downloadManager.downloadModel(model)
    }
}

// Register strategy
sdk.registerModuleDownloadStrategy(YourDownloadStrategy())
```

### 5. Download Models Using SDK

```swift
public func loadModel(_ modelId: String) async throws {
    // Check if downloaded
    if !sdk.isModelDownloaded(modelId) {
        // Download with progress
        let helper = ModuleIntegrationHelper(sdk: sdk)
        let localPath = try await helper.downloadModelWithProgress(modelId) { progress in
            print("Download progress: \(progress.percentage)%")
        }
    }

    // Get local path
    guard let modelPath = await sdk.getModelLocalPath(for: modelId) else {
        throw ModuleError.modelNotFound(modelId)
    }

    // Load your model from modelPath
}
```

---

## SDK APIs for Modules

### Core APIs

| API | Purpose |
|-----|---------|
| `getFrameworkStorageDirectory(for:)` | Get storage directory for your framework |
| `createModuleCache(moduleId:)` | Create cache directory |
| `clearModuleCache(moduleId:)` | Clear cache |
| `registerModuleModels(_:)` | Register models with SDK |
| `downloadModel(_:)` | Download model using SDK infrastructure |
| `isModelDownloaded(_:)` | Check if model is downloaded |
| `getModelLocalPath(for:)` | Get local path of downloaded model |
| `registerModuleDownloadStrategy(_:)` | Register custom download strategy |

### Helper Classes

#### ModuleIntegrationHelper
```swift
let helper = ModuleIntegrationHelper(sdk: sdk)

// Download with progress
let path = try await helper.downloadModelWithProgress(modelId) { progress in
    updateUI(progress)
}

// Register and download from URL
let path = try await helper.registerAndDownloadModel(
    name: "Model Name",
    url: modelURL,
    framework: .custom("your-framework")
)
```

---

## Module Types

### Voice Modules (TTS/STT)

```swift
// For TTS modules
public class YourTTSService: TextToSpeechService {
    // Implement protocol methods
}

// For STT modules
public class YourSTTService: SpeechToTextService {
    // Implement protocol methods
}
```

### LLM Modules

```swift
public class YourLLMService: LLMService {
    // Implement protocol methods
}
```

---

## Best Practices

### 1. **Dependency Management**
- Always depend on the SDK, not other modules
- Use SDK's infrastructure instead of reimplementing
- Keep external dependencies minimal
- Use `@preconcurrency import` for SDK when needed

### 2. **Initialization Patterns**

**Option A: Async Init (FluidAudioDiarization style)**
```swift
public init(threshold: Float = 0.65) async throws {
    // Everything in async init
    // Download models here
    // Initialize everything
}
```

**Option B: Two-Phase (SherpaONNXTTS style)**
```swift
public init(sdk: RunAnywhereSDK = .shared) {
    self.sdk = sdk
    // Light setup only
    registerModels()
}

public func initialize() async throws {
    // Heavy work here
    // Download models
    // Initialize resources
}
```

### 3. **Error Handling**
```swift
// Use ModuleError for consistent error handling
throw ModuleError.initializationFailed("Reason")
throw ModuleError.modelDownloadFailed(modelId)
```

### 4. **Model Management**
- Register all models on init
- Use SDK's download infrastructure
- Store models in framework-specific folders
- Clean up cache appropriately

### 5. **Factory Pattern** (Optional)
```swift
// Apps can discover your module dynamically
if RunAnywhereSDK.isModuleAvailable("YourModule.YourService") {
    // Module is available
}
```

### 6. **Lifecycle Management**
```swift
extension YourService: ModuleLifecycle {
    func moduleWillInitialize() async throws {
        // Pre-init setup
    }

    func moduleDidInitialize() async {
        // Post-init setup
    }

    func isModuleReady() -> Bool {
        return isInitialized
    }
}
```

### 7. **Configuration**
```swift
public struct YourModuleConfig: ModuleConfiguration {
    public let moduleId = "your-module"
    public let version = "1.0.0"
    public let requiredSDKVersion = "1.0.0"
    public let dependencies: [String] = []
}
```

### 8. **Logging**
```swift
// Use os.Logger for consistent logging
import os

private let logger = Logger(
    subsystem: "com.runanywhere.sdk",
    category: "YourModule"
)

// Usage
logger.info("Module initialized")
logger.error("Failed to load model: \(error)")
```

### 9. **Thread Safety**
```swift
// Use queues for thread-safe operations (FluidAudioDiarization pattern)
private let queue = DispatchQueue(
    label: "com.runanywhere.yourmodule",
    attributes: .concurrent
)

// Read operations
queue.sync { /* read */ }

// Write operations
queue.async(flags: .barrier) { /* write */ }
```

---

## Real-World Examples

### FluidAudioDiarization Pattern (Self-Contained)
```swift
import Foundation
@preconcurrency import RunAnywhereSDK  // Import SDK for protocols
import FluidAudio  // External dependency
import os

@available(iOS 16.0, macOS 13.0, *)
public class FluidAudioDiarization: SpeakerDiarizationProtocol {
    private let logger = Logger(subsystem: "com.runanywhere.sdk", category: "FluidAudioDiarization")

    // Async init that handles everything internally
    public init(threshold: Float = 0.65) async throws {
        // Configure with defaults
        var config = DiarizerConfig.default
        config.clusteringThreshold = threshold

        // Download models internally (not using SDK)
        logger.info("Downloading FluidAudio models...")
        let models = try await DiarizerModels.downloadIfNeeded()

        // Initialize
        diarizerManager.initialize(models: models)
    }

    // Key insights:
    // - Self-contained: handles own downloads
    // - Uses SDK protocols but not infrastructure
    // - Async init for heavy operations
    // - Platform availability checks
}
```

### SherpaONNXTTS Pattern (SDK-Integrated)
```swift
import RunAnywhereSDK  // Full SDK integration

public class SherpaONNXTTSService: TextToSpeechService {
    private let sdk: RunAnywhereSDK

    // Sync init, register with SDK
    public init(sdk: RunAnywhereSDK = .shared) {
        self.sdk = sdk
        registerModels()  // Register with SDK immediately
    }

    // Async initialization using SDK
    public func initialize() async throws {
        // Use SDK infrastructure for downloads
        if !sdk.isModelDownloaded(modelId) {
            _ = try await sdk.downloadModel(modelId)
        }

        // Get paths from SDK
        guard let localPath = await sdk.getModelLocalPath(for: modelId) else {
            throw SherpaONNXError.modelNotFound
        }

        // Initialize with SDK-managed resources
    }

    // Key insights:
    // - Leverages SDK infrastructure
    // - Sync init, async initialize pattern
    // - Uses SDK for all file/model management
}
```

---

## Testing Your Module

### Unit Tests
```swift
func testModuleInitialization() async throws {
    let service = YourModuleService()
    try await service.initialize()
    XCTAssertTrue(service.isReady)
}
```

### Integration Tests
```swift
func testSDKIntegration() async throws {
    let sdk = RunAnywhereSDK.shared
    try await sdk.initialize(apiKey: "test")

    let service = YourModuleService(sdk: sdk)
    try await service.initialize()

    // Test with SDK features
}
```

---

## Checklist

Before releasing your module:

- [ ] Module follows SDK dependency pattern
- [ ] Models are registered with SDK
- [ ] Uses SDK file management for storage
- [ ] Implements appropriate service protocol
- [ ] Handles initialization asynchronously
- [ ] Includes proper error handling
- [ ] Has unit and integration tests
- [ ] Documentation is complete
- [ ] Package.swift is properly configured
- [ ] Module can be discovered dynamically (optional)

---

## Support

For questions or issues:
- Review existing modules: `FluidAudioDiarization`, `SherpaONNXTTS`
- Check SDK source: `Public/Extensions/ModuleSupport/`
- File issues on GitHub

---

*This guide is part of the RunAnywhere SDK documentation. Last updated with SDK version 1.0.0*
