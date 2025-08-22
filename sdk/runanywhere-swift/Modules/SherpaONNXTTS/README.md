# SherpaONNX TTS Module

A Swift Package Manager module that integrates Sherpa-ONNX neural text-to-speech engine with the RunAnywhere SDK.

## 🚀 Quick Start

### First Time Setup

```bash
# 1. Clone the repository
git clone [your-repo-url]
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS

# 2. Set up frameworks (one-time, 10-15 minutes)
./setup_frameworks.sh

# 3. Build and test
swift build
swift test
```

That's it! The setup script handles all the complex framework building automatically.

### For Team Members

If someone on your team has already set up the frameworks:

```bash
# Just clone and build - frameworks will be set up automatically
git clone [your-repo-url]
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
swift build  # May trigger automatic framework setup
```

## ✨ Features

- **Neural TTS**: High-quality speech synthesis using state-of-the-art models
- **Multiple Model Types**: Support for KittenTTS, VITS, Kokoro, Matcha, and Piper models
- **On-Device Processing**: Privacy-first, offline text-to-speech synthesis
- **Multi-Voice Support**: Switch between different voices and speakers
- **Streaming Synthesis**: Real-time audio generation with progress callbacks
- **Cross-Platform**: iOS, macOS, tvOS, and watchOS support
- **Team-Friendly**: Automated setup with build-on-demand frameworks

## 📋 Usage

### Basic Synthesis

```swift
import SherpaONNXTTS

// Configure the TTS service
let config = SherpaONNXConfiguration(
    modelPath: modelURL,
    modelType: .kitten, // or .kokoro, .vits, .matcha, .piper
    sampleRate: 16000,
    numThreads: 2
)

// Initialize the service
let ttsService = SherpaONNXTTSService()
try await ttsService.initialize(with: config)

// Synthesize speech
let audioData = try await ttsService.synthesize(
    text: "Hello, world! This is neural text-to-speech.",
    voice: nil, // Use default voice
    rate: 1.0,
    pitch: 1.0,
    volume: 1.0
)
```

### Voice Management

```swift
// Get available voices
let voices = await ttsService.getAvailableVoices()

// Switch to a specific voice
try await ttsService.setVoice(voices.first?.identifier ?? "")
```

### Streaming Synthesis

```swift
// Stream audio for long text
let stream = ttsService.synthesizeStream(
    text: "Long text for real-time synthesis...",
    voice: nil, rate: 1.0, pitch: 1.0, volume: 1.0
)

for try await audioChunk in stream {
    // Process audio chunks as they arrive
    audioPlayer.append(audioChunk)
}
```

## 🎯 Supported Models

| Model | Size | Quality | Speed | Languages | Best For |
|-------|------|---------|--------|-----------|----------|
| **KittenTTS** | ~50MB | High | Fast | English | Recommended for most apps |
| **Kokoro** | ~100MB | Very High | Medium | Multi-language | International apps |
| **VITS** | ~200MB | High | Medium | English | Traditional TTS |
| **Matcha** | ~150MB | Very High | Slow | English | High-quality applications |
| **Piper** | ~30MB | Good | Very Fast | English | Resource-constrained devices |

## 🔧 Team Workflow

### Framework Management

This module uses **build-on-demand** framework management:

- ✅ **Clean Git repo**: No 300MB+ binaries committed
- ✅ **Fast setup**: One script handles everything
- ✅ **Team-friendly**: Automatic setup for new developers
- ✅ **CI/CD ready**: Automated framework building

### Team Development Scenarios

**New Team Member:**
```bash
./setup_frameworks.sh  # One-time setup
swift build            # Ready to go!
```

**Framework Updates:**
```bash
rm -rf XCFrameworks/   # Force rebuild
./setup_frameworks.sh  # Get latest version
```

**CI/CD Integration:**
```yaml
- name: Setup Frameworks
  run: |
    cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
    ./setup_frameworks.sh
```

### Shared Team Storage (Advanced)

For faster team onboarding, you can host pre-built frameworks:

```bash
# Set up shared storage URL
export SHERPA_FRAMEWORKS_URL="https://your-storage.com/frameworks.tar.gz"
./setup_frameworks.sh  # Downloads instead of building
```

## 📚 Documentation

- **[BUILD_DOCUMENTATION.md](BUILD_DOCUMENTATION.md)** - Complete build process and technical details
- **[TEAM_WORKFLOW.md](TEAM_WORKFLOW.md)** - Detailed team collaboration guide
- **[INTEGRATION_SUMMARY.md](INTEGRATION_SUMMARY.md)** - Implementation completion summary

## 🏗️ Architecture

Modern Swift architecture with industry best practices:

```
SherpaONNXTTS/
├── Sources/
│   ├── SherpaONNXTTS/           # Swift layer (async/await, modern patterns)
│   └── SherpaONNXBridge/        # Objective-C++ bridge to native code
├── XCFrameworks/                # Binary frameworks (built by setup script)
├── setup_frameworks.sh         # Automated framework setup
└── Tests/                       # Comprehensive test suite
```

**Key Technical Features:**
- **Async/Await**: Modern Swift concurrency patterns
- **Error Handling**: Comprehensive Swift-native error types
- **Memory Management**: Automatic cleanup and resource management
- **Thread Safety**: Dedicated queues for native operations
- **Streaming**: AsyncThrowingStream for real-time synthesis

## 🔍 Troubleshooting

### Quick Fixes

**"Framework not found" errors:**
```bash
./setup_frameworks.sh  # Re-run setup
```

**"CMake not found":**
```bash
brew install cmake     # Install CMake
```

**Build timeouts in CI:**
```bash
# Cache the EXTERNAL directory in your CI config
```

### Performance Tips

- **Memory**: Use KittenTTS for memory-constrained devices
- **Speed**: Increase `numThreads` for faster synthesis
- **Quality**: Use Kokoro or Matcha for highest quality

## 📊 Performance

- **Setup Time**: 10-15 minutes (first time only)
- **Synthesis Speed**: 5-20x real-time
- **Memory Usage**: 100-300MB (model dependent)
- **Initialization**: 1-3 seconds

## 📋 Requirements

- **iOS**: 15.0+ / **macOS**: 12.0+ / **tvOS**: 15.0+ / **watchOS**: 8.0+
- **Xcode**: 15.0+ / **Swift**: 5.9+
- **CMake**: 3.20+ (installed automatically by setup script)

## 🎉 Integration with RunAnywhere

```swift
import RunAnywhereSDK

// Configure voice pipeline with SherpaONNX TTS
let pipelineConfig = ModularPipelineConfig(
    components: [.vad, .stt, .llm, .tts],
    tts: VoiceTTSConfig.sherpaONNX(
        modelId: "sherpa-kitten-nano-v0.1",
        voice: "expr-voice-1-f",
        rate: 1.0
    )
)

let pipeline = RunAnywhereSDK.shared.createVoicePipeline(config: pipelineConfig)
```

## 📄 License

This module uses Sherpa-ONNX (Apache 2.0). See [Sherpa-ONNX repository](https://github.com/k2-fsa/sherpa-onnx) for details.

---

**🎯 Ready for Production**: Scalable • Maintainable • Team-Friendly • Well-Documented
