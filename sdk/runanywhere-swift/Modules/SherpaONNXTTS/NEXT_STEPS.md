# Next Steps for SherpaONNXTTS Module

## ✅ What's Been Completed

1. **Module Structure** - Complete package structure created
2. **Swift Implementation** - All Swift components implemented:
   - `SherpaONNXTTSService` - Main service
   - `SherpaONNXConfiguration` - Configuration types
   - `SherpaONNXModelManager` - Model management
   - `SherpaONNXDownloadStrategy` - Download handling
   - `SherpaONNXWrapper` - Swift wrapper (currently with mocks)
3. **Native Bridge** - Objective-C++ bridge created:
   - `SherpaONNXBridge.h` - Bridge header
   - `SherpaONNXBridge.mm` - Implementation (ready for XCFrameworks)
4. **Build Infrastructure**:
   - `build_frameworks.sh` - Automated build script
   - `Package.swift` - Configured for binary targets
5. **Documentation** - README and implementation plans

## 🚧 Immediate Next Steps

### Step 1: Build XCFrameworks (Required)

```bash
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
./build_frameworks.sh
```

This will:
- Clone sherpa-onnx repository
- Build sherpa-onnx.xcframework
- Build onnxruntime.xcframework
- Copy to XCFrameworks/ directory

**Expected time**: 10-15 minutes

### Step 2: Verify Framework Integration

After building, check that frameworks are present:
```bash
ls -la XCFrameworks/
# Should show:
# - sherpa-onnx.xcframework/
# - onnxruntime.xcframework/
```

### Step 3: Update Wrapper to Use Native Bridge

Once XCFrameworks are built, update `SherpaONNXWrapper.swift`:

1. Remove mock implementations
2. Use the native bridge:

```swift
import SherpaONNXFramework // This will now work

// In synthesize method:
guard let audioData = bridge.synthesizeText(
    text,
    speakerId: speakerId,
    speed: rate
) else {
    throw SherpaONNXError.synthesisFailure("Failed to generate audio")
}
```

### Step 4: Test Module Build

```bash
# From module directory
swift build

# Or if you have test models:
swift test
```

### Step 5: Add to Sample App

In Xcode:
1. Open your sample app project
2. File → Add Package Dependencies
3. Add Local Package
4. Navigate to: `sdk/runanywhere-swift/Modules/SherpaONNXTTS`
5. Add to target

### Step 6: Configure in App

```swift
// In your app
import SherpaONNXTTS

// Configure voice pipeline
let config = ModularPipelineConfig(
    components: [.vad, .stt, .llm, .tts],
    tts: VoiceTTSConfig.sherpaONNX(
        modelId: "sherpa-kitten-nano-v0.1"
    )
)
```

## 📝 Testing Checklist

- [ ] XCFrameworks built successfully
- [ ] Module compiles without errors
- [ ] Bridge can initialize TTS
- [ ] Can synthesize basic text
- [ ] Voice switching works
- [ ] Streaming synthesis works
- [ ] Memory is properly managed
- [ ] No crashes or leaks

## 🐛 Troubleshooting

### "No such module 'SherpaONNXFramework'"
- Run `./build_frameworks.sh` first
- Verify XCFrameworks exist in `XCFrameworks/` directory

### "Failed to create TTS instance"
- Check model files are downloaded
- Verify model path is correct
- Check console logs for specific errors

### Build errors with Objective-C++
- Ensure Xcode command line tools are installed
- Try cleaning build folder: `rm -rf .build/`

### Large binary size
- Consider using Git LFS for XCFrameworks
- Or add to .gitignore and build locally

## 📊 Performance Targets

Once integrated, verify:
- Initialization time: < 2 seconds
- Time to first audio: < 100ms
- Real-time factor: > 10x
- Memory usage: < 200MB for KittenTTS

## 🔄 Future Enhancements

After basic integration works:
1. Add progress callbacks for long text
2. Implement voice customization
3. Add SSML support
4. Optimize for specific devices
5. Add voice cloning support

## 📚 Resources

- [Sherpa-ONNX Docs](https://k2-fsa.github.io/sherpa/onnx/)
- [C API Reference](https://k2-fsa.github.io/sherpa/onnx/c-api/)
- [TTS Models](https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models.html)
- [iOS Examples](https://github.com/k2-fsa/sherpa-onnx/tree/master/ios-swift)

---

**Ready to proceed?** Start with Step 1: `./build_frameworks.sh`
