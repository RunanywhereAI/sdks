# SherpaONNXWrapper Native Bridge Implementation Plan

## Overview
This document outlines the plan to properly implement the SherpaONNXWrapper to bridge Swift code with the Sherpa-ONNX C++ TTS engine.

## Current State
- ✅ Placeholder wrapper created with mock implementation
- ✅ Mock voices and audio generation for testing
- ⚠️ TODO: Replace with actual Sherpa-ONNX C API calls
- ⚠️ TODO: Build and integrate XCFrameworks

## Dependencies Required
1. **sherpa-onnx.xcframework** - Main TTS engine
2. **onnxruntime.xcframework** - ONNX Runtime dependency

## Implementation Steps

### Phase 1: XCFramework Integration

#### 1.1 Build XCFrameworks
```bash
# Clone and build
git clone https://github.com/k2-fsa/sherpa-onnx.git EXTERNAL/sherpa-onnx
cd EXTERNAL/sherpa-onnx
./build-ios.sh

# Copy to module
cp -r build-ios/*.xcframework ../sdk/runanywhere-swift/Modules/SherpaONNXTTS/XCFrameworks/
```

#### 1.2 Create Objective-C++ Bridge Header
Create `SherpaONNXBridge.h`:
```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SherpaONNXBridge : NSObject

// Configuration
- (instancetype)initWithModelPath:(NSString *)modelPath
                         modelType:(NSString *)modelType
                        numThreads:(NSInteger)numThreads
                        sampleRate:(NSInteger)sampleRate;

// Synthesis
- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed;

// Voice management
- (NSInteger)numberOfSpeakers;
- (NSInteger)sampleRate;

// Cleanup
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
```

### Phase 2: Native Implementation

#### 2.1 Create Objective-C++ Implementation
Create `SherpaONNXBridge.mm`:
```objc++
#import "SherpaONNXBridge.h"
#import "sherpa-onnx/c-api/c-api.h"
#include <vector>
#include <string>

@interface SherpaONNXBridge () {
    SherpaOnnxOfflineTts *tts;
    int32_t sampleRate;
}
@end

@implementation SherpaONNXBridge

- (instancetype)initWithModelPath:(NSString *)modelPath
                         modelType:(NSString *)modelType
                        numThreads:(NSInteger)numThreads
                        sampleRate:(NSInteger)sampleRate {
    self = [super init];
    if (self) {
        [self setupTTSWithPath:modelPath type:modelType threads:numThreads];
    }
    return self;
}

- (void)setupTTSWithPath:(NSString *)modelPath
                    type:(NSString *)modelType
                 threads:(NSInteger)numThreads {
    SherpaOnnxOfflineTtsConfig config;
    memset(&config, 0, sizeof(config));

    // Configure based on model type
    if ([modelType isEqualToString:@"kitten"]) {
        config.model.kitten.model = [modelPath UTF8String];
        config.model.kitten.tokens = [[modelPath stringByAppendingPathComponent:@"tokens.txt"] UTF8String];
        config.model.kitten.data_dir = [[modelPath stringByAppendingPathComponent:@"espeak-ng-data"] UTF8String];
        config.model.provider = "cpu";
        config.model.num_threads = (int32_t)numThreads;
    } else if ([modelType isEqualToString:@"vits"]) {
        config.model.vits.model = [modelPath UTF8String];
        config.model.vits.tokens = [[modelPath stringByAppendingPathComponent:@"tokens.txt"] UTF8String];
        config.model.provider = "cpu";
        config.model.num_threads = (int32_t)numThreads;
    }
    // Add other model types...

    // Create TTS instance
    tts = SherpaOnnxCreateOfflineTts(&config);
    if (tts) {
        sampleRate = SherpaOnnxOfflineTtsSampleRate(tts);
    }
}

- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed {
    if (!tts) return nil;

    const SherpaOnnxGeneratedAudio *audio = SherpaOnnxOfflineTtsGenerate(
        tts,
        [text UTF8String],
        (int32_t)speakerId,
        speed
    );

    if (!audio) return nil;

    // Convert float samples to NSData
    NSData *audioData = [NSData dataWithBytes:audio->samples
                                        length:audio->n * sizeof(float)];

    // Free the generated audio
    SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio);

    return audioData;
}

- (NSInteger)numberOfSpeakers {
    return tts ? SherpaOnnxOfflineTtsNumSpeakers(tts) : 0;
}

- (NSInteger)sampleRate {
    return sampleRate;
}

- (void)destroy {
    if (tts) {
        SherpaOnnxDestroyOfflineTts(tts);
        tts = nullptr;
    }
}

- (void)dealloc {
    [self destroy];
}

@end
```

### Phase 3: Swift Wrapper Update

#### 3.1 Update SherpaONNXWrapper.swift
```swift
import Foundation
import AVFoundation
import RunAnywhereSDK
import SherpaONNXFramework  // Import the framework
import os

final class SherpaONNXWrapper {
    private var bridge: SherpaONNXBridge?
    private let configuration: SherpaONNXConfiguration

    init(configuration: SherpaONNXConfiguration) async throws {
        self.configuration = configuration

        // Initialize native bridge
        bridge = SherpaONNXBridge(
            modelPath: configuration.modelPath.path,
            modelType: configuration.modelType.rawValue,
            numThreads: configuration.numThreads,
            sampleRate: configuration.sampleRate
        )

        guard bridge != nil else {
            throw SherpaONNXError.frameworkNotLoaded
        }

        // Initialize voices based on model
        initializeVoicesFromModel()
    }

    func synthesize(text: String, rate: Float, pitch: Float, volume: Float) async throws -> Data {
        guard let bridge = bridge else {
            throw SherpaONNXError.notInitialized
        }

        // Map voice to speaker ID
        let speakerId = getCurrentSpeakerId()

        // Synthesize using native bridge
        guard let audioData = bridge.synthesizeText(
            text,
            speakerId: speakerId,
            speed: rate
        ) else {
            throw SherpaONNXError.synthesisFailure("Failed to generate audio")
        }

        // Apply volume adjustment if needed
        return applyVolume(to: audioData, volume: volume)
    }

    func synthesizeStream(text: String, rate: Float, pitch: Float, volume: Float) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // For streaming, we need to chunk the text
                    let sentences = splitIntoSentences(text)

                    for sentence in sentences {
                        guard let audioChunk = bridge?.synthesizeText(
                            sentence,
                            speakerId: getCurrentSpeakerId(),
                            speed: rate
                        ) else {
                            throw SherpaONNXError.synthesisFailure("Stream synthesis failed")
                        }

                        continuation.yield(applyVolume(to: audioChunk, volume: volume))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func initializeVoicesFromModel() {
        guard let bridge = bridge else { return }

        let numSpeakers = bridge.numberOfSpeakers()
        voices = []

        // Create voice entries based on available speakers
        for i in 0..<numSpeakers {
            let voice = VoiceInfo(
                identifier: "speaker-\(i)",
                name: "Speaker \(i + 1)",
                language: "en-US",
                gender: .neutral
            )
            voices.append(voice)
        }

        selectedVoiceId = voices.first?.identifier
    }

    func cleanup() {
        bridge?.destroy()
        bridge = nil
    }
}
```

### Phase 4: Testing & Validation

#### 4.1 Unit Tests
```swift
func testSherpaONNXInitialization() async throws {
    let config = SherpaONNXConfiguration(
        modelPath: testModelPath,
        modelType: .kitten
    )

    let wrapper = try await SherpaONNXWrapper(configuration: config)
    XCTAssertNotNil(wrapper)
    XCTAssertFalse(wrapper.availableVoices.isEmpty)
}

func testSynthesis() async throws {
    let wrapper = try await createTestWrapper()
    let audioData = try await wrapper.synthesize(
        text: "Hello, world!",
        rate: 1.0,
        pitch: 1.0,
        volume: 1.0
    )

    XCTAssertFalse(audioData.isEmpty)
    // Verify audio format
    XCTAssertEqual(audioData.count % MemoryLayout<Float>.size, 0)
}
```

#### 4.2 Integration Tests
- Test with VoicePipelineManager
- Verify model downloads
- Test voice switching
- Validate audio output format

### Phase 5: Advanced Features

#### 5.1 Progress Callbacks
```swift
func synthesizeWithProgress(
    text: String,
    progressHandler: @escaping (Float) -> Void
) async throws -> Data {
    // Use SherpaOnnxOfflineTtsGenerateWithProgressCallback
    // Map C callback to Swift closure
}
```

#### 5.2 Custom Voice Support
```swift
func loadCustomVoice(from path: URL) throws {
    // Load speaker embeddings
    // Update voice list
}
```

#### 5.3 Audio Post-Processing
```swift
private func applyVolume(to audioData: Data, volume: Float) -> Data {
    guard volume != 1.0 else { return audioData }

    var samples = audioData.withUnsafeBytes { bytes in
        Array(bytes.bindMemory(to: Float.self))
    }

    // Apply volume scaling
    for i in 0..<samples.count {
        samples[i] *= volume
    }

    return Data(bytes: samples, count: samples.count * MemoryLayout<Float>.size)
}
```

## Build Script

Create `build_sherpa_onnx.sh`:
```bash
#!/bin/bash

# Build Sherpa-ONNX XCFrameworks for iOS

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
EXTERNAL_DIR="$PROJECT_ROOT/EXTERNAL"
MODULE_DIR="$PROJECT_ROOT/sdk/runanywhere-swift/Modules/SherpaONNXTTS"

echo "🔨 Building Sherpa-ONNX XCFrameworks..."

# Clone if not exists
if [ ! -d "$EXTERNAL_DIR/sherpa-onnx" ]; then
    echo "📥 Cloning sherpa-onnx..."
    git clone https://github.com/k2-fsa/sherpa-onnx.git "$EXTERNAL_DIR/sherpa-onnx"
fi

# Build
cd "$EXTERNAL_DIR/sherpa-onnx"
echo "🏗️ Building for iOS..."
./build-ios.sh

# Copy frameworks
echo "📦 Copying XCFrameworks..."
mkdir -p "$MODULE_DIR/XCFrameworks"
cp -r build-ios/sherpa-onnx.xcframework "$MODULE_DIR/XCFrameworks/"
cp -r build-ios/onnxruntime.xcframework "$MODULE_DIR/XCFrameworks/"

echo "✅ Build complete!"
echo "📍 Frameworks located at: $MODULE_DIR/XCFrameworks/"
```

## Module Integration Checklist

- [ ] Build sherpa-onnx.xcframework
- [ ] Build onnxruntime.xcframework
- [ ] Create Objective-C++ bridge header
- [ ] Implement bridge in .mm file
- [ ] Update SherpaONNXWrapper to use bridge
- [ ] Remove mock implementations
- [ ] Add proper voice management
- [ ] Implement streaming synthesis
- [ ] Add progress callbacks
- [ ] Write comprehensive tests
- [ ] Test with sample app
- [ ] Document API usage

## Expected File Structure After Implementation

```
Modules/SherpaONNXTTS/
├── Sources/
│   └── SherpaONNXTTS/
│       ├── Public/
│       │   ├── SherpaONNXTTSService.swift
│       │   └── SherpaONNXConfiguration.swift
│       ├── Internal/
│       │   ├── Bridge/
│       │   │   ├── SherpaONNXWrapper.swift
│       │   │   ├── SherpaONNXBridge.h        # NEW
│       │   │   └── SherpaONNXBridge.mm       # NEW
│       │   └── Models/
│       │       ├── SherpaONNXModelManager.swift
│       │       └── SherpaONNXDownloadStrategy.swift
│       └── Resources/
│           └── module.modulemap               # NEW - For C++ interop
└── XCFrameworks/
    ├── sherpa-onnx.xcframework/              # Built from source
    └── onnxruntime.xcframework/              # Downloaded by build script
```

## Module Map for C++ Interop

Create `module.modulemap`:
```
module SherpaONNXBridge {
    header "SherpaONNXBridge.h"
    export *
}
```

## Notes

1. **Memory Management**: The C API returns allocated memory that must be freed
2. **Thread Safety**: Sherpa-ONNX handle is not thread-safe, use serial queue
3. **Audio Format**: Output is Float32 PCM at specified sample rate (usually 16kHz or 24kHz)
4. **Model Loading**: Models are loaded once during initialization
5. **Error Handling**: Check all C API return values for null

## Resources

- [Sherpa-ONNX C API Documentation](https://k2-fsa.github.io/sherpa/onnx/c-api/index.html)
- [iOS Build Instructions](https://k2-fsa.github.io/sherpa/onnx/ios/build-sherpa-onnx-swift.html)
- [TTS Model Documentation](https://k2-fsa.github.io/sherpa/onnx/tts/index.html)
