# SherpaONNXTTS Module

High-quality neural Text-to-Speech module for RunAnywhere SDK using Sherpa-ONNX.

## Features

- 🎯 Multiple TTS models (Kitten, Kokoro, VITS, Matcha)
- 🗣️ Multiple voices per model
- 🌍 Multi-language support
- ⚡ Real-time synthesis
- 📱 On-device processing (no internet required)
- 🔄 Streaming synthesis support

## Setup

### Prerequisites

- macOS with Xcode 14.2+
- CMake 3.25.1+
- iOS deployment target: iOS 13.0+

### Building XCFrameworks

The module requires two XCFrameworks that must be built from source:

1. **sherpa-onnx.xcframework** - The TTS engine
2. **onnxruntime.xcframework** - ONNX Runtime dependency

#### Quick Build

```bash
# From the module directory
./build_frameworks.sh
```

This script will:
1. Clone sherpa-onnx repository
2. Build XCFrameworks for all iOS architectures
3. Copy frameworks to `XCFrameworks/` directory
4. Verify installation

#### Manual Build

If you prefer to build manually:

```bash
# Clone sherpa-onnx
git clone https://github.com/k2-fsa/sherpa-onnx.git
cd sherpa-onnx

# Build for iOS
./build-ios.sh

# Copy frameworks
cp -r build-ios/*.xcframework path/to/SherpaONNXTTS/XCFrameworks/
```

## Integration

### 1. Add to Your App

In Xcode:
1. File → Add Package Dependencies
2. Click "Add Local..."
3. Navigate to `sdk/runanywhere-swift/Modules/SherpaONNXTTS`
4. Add the package

### 2. Import and Use

```swift
import SherpaONNXTTS
import RunAnywhereSDK

// Initialize the service
let ttsService = SherpaONNXTTSService()
try await ttsService.initialize()

// Synthesize speech
let audioData = try await ttsService.synthesize(
    text: "Hello, world!",
    options: TTSOptions(voice: "expr-voice-1-f", rate: 1.0)
)

// Or use streaming
let stream = ttsService.synthesizeStream(text: longText, options: nil)
for try await chunk in stream {
    // Play audio chunk
}
```

### 3. Configure in Voice Pipeline

```swift
let config = ModularPipelineConfig(
    components: [.vad, .stt, .llm, .tts],
    tts: VoiceTTSConfig.sherpaONNX(
        modelId: "sherpa-kitten-nano-v0.1",
        voice: "expr-voice-2-f"
    )
)
```

## Supported Models

| Model | Size | Voices | Quality | Languages |
|-------|------|--------|---------|-----------|
| Kitten TTS | 25MB | 8 | Good | English |
| Kokoro | 100MB | 11+ | Excellent | Multi |
| VITS | 50-150MB | Varies | Good | 30+ |
| Matcha | 100-300MB | Varies | Best | Multi |

## Project Structure

```
SherpaONNXTTS/
├── Sources/
│   └── SherpaONNXTTS/
│       ├── Public/
│       │   ├── SherpaONNXTTSService.swift      # Main service
│       │   └── SherpaONNXConfiguration.swift   # Configuration
│       ├── Internal/
│       │   ├── Bridge/
│       │   │   ├── SherpaONNXWrapper.swift     # Swift wrapper
│       │   │   ├── SherpaONNXBridge.h          # ObjC++ header
│       │   │   └── SherpaONNXBridge.mm         # ObjC++ implementation
│       │   └── Models/
│       │       ├── SherpaONNXModelManager.swift
│       │       └── SherpaONNXDownloadStrategy.swift
│       └── module.modulemap                     # C++ interop
├── XCFrameworks/                                # Built frameworks go here
│   ├── sherpa-onnx.xcframework/
│   └── onnxruntime.xcframework/
├── Package.swift
├── build_frameworks.sh                         # Build script
└── README.md
```

## Troubleshooting

### Build Errors

1. **"No such module 'SherpaONNXFramework'"**
   - Run `./build_frameworks.sh` to build the XCFrameworks
   - Verify frameworks exist in `XCFrameworks/` directory

2. **"Failed to build sherpa-onnx"**
   - Ensure CMake is installed: `brew install cmake`
   - Check Xcode is properly installed: `xcode-select --install`

3. **Large Framework Size**
   - Consider using Git LFS for the XCFrameworks
   - Or add `XCFrameworks/` to `.gitignore` and build locally

### Runtime Issues

1. **Model not found**
   - Ensure model is registered with SDK
   - Check model download completed successfully

2. **No voices available**
   - Verify model files include voice data
   - Check model type matches configuration

## Development

### Running Tests

```bash
swift test
```

### Adding New Models

1. Add model definition in `SherpaONNXModelManager.swift`
2. Update model type enum in `SherpaONNXConfiguration.swift`
3. Add voice mappings in `SherpaONNXWrapper.swift`

## License

This module uses Sherpa-ONNX which is licensed under Apache 2.0.
ONNX Runtime is licensed under MIT.

## Resources

- [Sherpa-ONNX Documentation](https://k2-fsa.github.io/sherpa/onnx/)
- [TTS Models](https://k2-fsa.github.io/sherpa/onnx/tts/index.html)
- [iOS Build Guide](https://k2-fsa.github.io/sherpa/onnx/ios/build-sherpa-onnx-swift.html)
