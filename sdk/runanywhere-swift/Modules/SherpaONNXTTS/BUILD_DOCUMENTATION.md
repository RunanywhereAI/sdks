# SherpaONNX TTS Module - Build Documentation

## Overview

This document details the complete end-to-end process for building and integrating the Sherpa-ONNX Text-to-Speech module with the RunAnywhere Swift SDK. This documentation follows industry best practices for Swift Package Manager, XCFramework distribution, and mixed-language (Swift + Objective-C++) module development.

## Architecture & Best Practices

### 1. **Separation of Concerns**
- **Swift Layer**: High-level API, async/await patterns, error handling
- **Objective-C++ Bridge**: Interface between Swift and C++ native code
- **Binary Distribution**: XCFrameworks for multi-architecture support

### 2. **Industry-Standard Patterns**
- **Swift Package Manager**: Modern dependency management
- **XCFramework**: Apple's recommended binary distribution format
- **Conditional Compilation**: `#ifdef` guards for framework availability
- **Async/Await**: Modern Swift concurrency patterns
- **Error Handling**: Swift-native error types and handling

### 3. **Scalability Considerations**
- **Modular Design**: Separate package for easy integration
- **Version Control**: Independent versioning from main SDK
- **Binary Caching**: Pre-built frameworks reduce build times
- **Multi-Platform**: iOS, macOS, tvOS, watchOS support

## Complete Build Process

### Step 1: Prerequisites

```bash
# Required tools
brew install cmake
xcode-select --install

# Verify versions
cmake --version  # Should be >= 3.20
xcodebuild -version  # Should be Xcode 15+
```

### Step 2: Clone and Build Sherpa-ONNX

```bash
# Navigate to external dependencies directory
cd /path/to/your/project/EXTERNAL

# Clone sherpa-onnx repository
git clone --recursive https://github.com/k2-fsa/sherpa-onnx.git
cd sherpa-onnx

# Use the iOS build script (creates XCFrameworks automatically)
./build-ios.sh
```

**What this does:**
1. Downloads and builds ONNX Runtime for iOS
2. Builds espeak-ng, piper-phonemize, and other TTS dependencies
3. Compiles Sherpa-ONNX for multiple architectures:
   - `ios-arm64` (device)
   - `ios-arm64_x86_64-simulator` (simulator)
4. Creates XCFramework bundles with proper headers
5. Builds all TTS model types (Kitten, VITS, Kokoro, Matcha)

**Build output locations:**
- `build-ios/sherpa-onnx.xcframework` - Main TTS framework
- `build-ios/ios-onnxruntime/onnxruntime.xcframework` - ONNX Runtime

### Step 3: Framework Integration (Automated)

**For Team Development (Recommended):**

```bash
# Navigate to TTS module directory
cd /path/to/SherpaONNXTTS

# Run automated setup script
./setup_frameworks.sh

# This script will:
# 1. Check if frameworks already exist
# 2. Download pre-built frameworks (if URL configured)
# 3. Or build from source automatically
# 4. Verify framework integrity
```

**Manual Integration (Advanced):**

```bash
# Only if you need manual control
cp -R /path/to/sherpa-onnx/build-ios/sherpa-onnx.xcframework XCFrameworks/
cp -R /path/to/sherpa-onnx/build-ios/ios-onnxruntime/1.17.1/onnxruntime.xcframework XCFrameworks/
```

### Step 4: Package.swift Configuration

The Package.swift uses modern SPM patterns:

```swift
// Binary targets for XCFrameworks
.binaryTarget(
    name: "SherpaONNXFramework",
    path: "XCFrameworks/sherpa-onnx.xcframework"
),
.binaryTarget(
    name: "ONNXRuntimeFramework",
    path: "XCFrameworks/onnxruntime.xcframework"
)

// Separate target for Objective-C++ bridge
.target(
    name: "SherpaONNXBridge",
    dependencies: ["SherpaONNXFramework", "ONNXRuntimeFramework"],
    path: "Sources/SherpaONNXBridge",
    publicHeadersPath: ".",
    cxxSettings: [
        .define("SHERPA_ONNX_AVAILABLE", .when(platforms: [.iOS, .macOS])),
        .headerSearchPath("../../XCFrameworks/sherpa-onnx.xcframework/Headers"),
        .headerSearchPath("../../XCFrameworks/onnxruntime.xcframework/Headers")
    ]
)
```

**Key Best Practices:**
- **Separate targets** for Swift and Objective-C++ (SPM requirement)
- **Conditional compilation** with `SHERPA_ONNX_AVAILABLE`
- **Explicit header search paths** for XCFramework headers
- **Platform-specific builds** using `.when(platforms:)`

### Step 5: Objective-C++ Bridge Implementation

The bridge follows Apple's recommended patterns:

```objc++
// SherpaONNXBridge.mm
#ifdef SHERPA_ONNX_AVAILABLE
#include "sherpa-onnx/c-api/c-api.h"
#else
// Fallback types for development without frameworks
typedef void SherpaOnnxOfflineTts;
#endif

@interface SherpaONNXBridge () {
#ifdef SHERPA_ONNX_AVAILABLE
    const SherpaOnnxOfflineTts *tts;  // Note: const pointer as per API
#else
    void *tts;
#endif
    int32_t _sampleRate;
    int32_t _numSpeakers;
}
@end
```

**API Corrections Made:**
1. **Function signature**: `SherpaOnnxCreateOfflineTts` returns `const SherpaOnnxOfflineTts *`
2. **Matcha model config**: Removed `noise_scale_w` (doesn't exist in actual API)
3. **Header includes**: Use `#include` instead of `#import` for C headers

### Step 6: Swift Wrapper Integration

The Swift wrapper uses modern concurrency patterns:

```swift
// Modern async/await patterns
func synthesize(text: String, rate: Float, pitch: Float, volume: Float) async throws -> Data

// AsyncThrowingStream for real-time generation
func synthesizeStream(...) -> AsyncThrowingStream<Data, Error>

// Actor-based thread safety (when needed)
actor SherpaONNXEngine { ... }
```

## Framework Architecture Details

### XCFramework Structure

```
sherpa-onnx.xcframework/
├── Info.plist                    # Framework metadata
├── Headers/                      # Public headers
│   ├── sherpa-onnx/
│   │   └── c-api/
│   │       └── c-api.h          # Main C API
│   └── cargs.h                  # Command line parsing
├── ios-arm64/                   # Device architecture
│   └── sherpa-onnx.a           # Static library
└── ios-arm64_x86_64-simulator/ # Simulator architectures
    └── sherpa-onnx.a           # Static library
```

### Supported TTS Models

The implementation supports all major Sherpa-ONNX model types:

1. **KittenTTS** (`kitten`): Lightweight, expressive voices
2. **VITS** (`vits`): Traditional VITS-based synthesis
3. **Kokoro** (`kokoro`): Multi-language support
4. **Matcha** (`matcha`): Advanced acoustic modeling
5. **Piper** (`piper`): Community-driven voices

## Testing & Validation

### Build Verification

```bash
# Test module compilation
cd /path/to/SherpaONNXTTS
swift build

# Run unit tests
swift test

# Test with specific platform
swift build --destination generic/platform=iOS
```

### Integration Testing

```swift
// Example integration test
func testTTSIntegration() async throws {
    let config = SherpaONNXConfiguration(
        modelPath: modelURL,
        modelType: .kitten
    )

    let wrapper = try await SherpaONNXWrapper(configuration: config)
    let audioData = try await wrapper.synthesize(
        text: "Hello, world!",
        rate: 1.0,
        pitch: 1.0,
        volume: 1.0
    )

    XCTAssertFalse(audioData.isEmpty)
}
```

## Troubleshooting

### Common Issues & Solutions

#### 1. "No such module 'SherpaONNXFramework'"
**Solution**: Run the framework build process first:
```bash
cd EXTERNAL/sherpa-onnx && ./build-ios.sh
```

#### 2. "Header file not found"
**Solution**: Verify XCFramework structure and header search paths:
```bash
find XCFrameworks -name "*.h" | head -5
```

#### 3. "Undefined symbols" during linking
**Solution**: Check that both frameworks are properly copied:
```bash
ls -la XCFrameworks/
# Should show both sherpa-onnx.xcframework and onnxruntime.xcframework
```

#### 4. "Mixed language source files not supported"
**Solution**: Ensure Swift and Objective-C++ are in separate targets (already implemented).

## Future Updates & Maintenance

### Updating Sherpa-ONNX

When Sherpa-ONNX releases new versions:

1. **Update source**:
   ```bash
   cd EXTERNAL/sherpa-onnx
   git pull origin master
   git submodule update --recursive
   ```

2. **Rebuild frameworks**:
   ```bash
   rm -rf build-ios/  # Clean previous builds
   ./build-ios.sh     # Rebuild with new version
   ```

3. **Copy updated frameworks**:
   ```bash
   cd /path/to/SherpaONNXTTS
   rm -rf XCFrameworks/*
   cp -R ../EXTERNAL/sherpa-onnx/build-ios/sherpa-onnx.xcframework XCFrameworks/
   cp -R ../EXTERNAL/sherpa-onnx/build-ios/ios-onnxruntime/*/onnxruntime.xcframework XCFrameworks/
   ```

4. **Test API compatibility**:
   ```bash
   swift build  # Check for compilation errors
   swift test   # Run tests
   ```

5. **Update bridge if needed**: Check for API changes in `c-api.h` and update bridge accordingly.

### API Evolution

Monitor Sherpa-ONNX GitHub for:
- **New model types**: Add support in `SherpaONNXModelType` enum
- **API changes**: Update bridge implementation
- **Performance improvements**: Update configuration options

## Performance Considerations

### Memory Management
- XCFrameworks are ~200MB total (acceptable for TTS quality)
- Runtime memory usage: ~100-200MB per model
- Use lazy loading for models to reduce startup time

### Build Optimization
- Consider using Git LFS for large XCFrameworks
- Implement caching in CI/CD pipelines
- Use `--configuration release` for production builds

## Security & Distribution

### Code Signing
```bash
# Sign frameworks for distribution
codesign --sign "Developer ID" XCFrameworks/*.xcframework
```

### Privacy
- All processing happens on-device
- No network requests for synthesis
- Model files stored locally

## Integration Checklist

- [ ] XCFrameworks built successfully
- [ ] Module compiles without errors
- [ ] Bridge can initialize TTS engine
- [ ] Basic synthesis works
- [ ] Voice switching functional
- [ ] Memory properly managed
- [ ] Tests pass
- [ ] Documentation updated

## Conclusion

This build process follows Apple's recommended practices for:
- **Swift Package Manager** integration
- **XCFramework** distribution
- **Mixed-language** module development
- **Modern Swift** concurrency patterns

The architecture is designed for:
- **Scalability**: Easy to add new model types
- **Maintainability**: Clear separation of concerns
- **Performance**: Optimized for on-device inference
- **Reliability**: Comprehensive error handling and testing

For questions or issues, refer to:
- [Sherpa-ONNX Documentation](https://k2-fsa.github.io/sherpa/onnx/)
- [Swift Package Manager Guide](https://swift.org/package-manager/)
- [Apple XCFramework Documentation](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle)
