//
//  SherpaONNXBridge.mm
//  SherpaONNXTTS
//
//  Objective-C++ implementation for Sherpa-ONNX C API bridge
//

#import "SherpaONNXBridge.h"

// Note: These headers will be available once XCFramework is built
// For now, this is a template implementation
#ifdef SHERPA_ONNX_AVAILABLE
#import <sherpa-onnx/c-api/c-api.h>
#endif

#include <vector>
#include <string>

@interface SherpaONNXBridge () {
#ifdef SHERPA_ONNX_AVAILABLE
    SherpaOnnxOfflineTts *tts;
#else
    void *tts; // Placeholder when framework not available
#endif
    int32_t _sampleRate;
    int32_t _numSpeakers;
}
@end

@implementation SherpaONNXBridge

#pragma mark - Initialization

- (nullable instancetype)initWithModelPath:(NSString *)modelPath
                                  modelType:(NSString *)modelType
                                 numThreads:(NSInteger)numThreads
                          maxSentenceLength:(NSInteger)maxSentenceLength {
    self = [super init];
    if (self) {
        if (![self setupTTSWithPath:modelPath
                               type:modelType
                            threads:numThreads
                    maxSentenceLength:maxSentenceLength]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)setupTTSWithPath:(NSString *)modelPath
                    type:(NSString *)modelType
                 threads:(NSInteger)numThreads
         maxSentenceLength:(NSInteger)maxSentenceLength {

#ifdef SHERPA_ONNX_AVAILABLE
    SherpaOnnxOfflineTtsConfig config;
    memset(&config, 0, sizeof(config));

    // Common configuration
    config.model.provider = "cpu";
    config.model.num_threads = (int32_t)numThreads;
    config.model.debug = 0;
    config.max_num_sentences = (int32_t)maxSentenceLength;

    // Model-specific configuration
    if ([modelType isEqualToString:@"kitten"]) {
        NSString *modelFile = [modelPath stringByAppendingPathComponent:@"model.onnx"];
        NSString *tokensFile = [modelPath stringByAppendingPathComponent:@"tokens.txt"];
        NSString *dataDir = [modelPath stringByAppendingPathComponent:@"espeak-ng-data"];

        config.model.kitten.model = [modelFile UTF8String];
        config.model.kitten.tokens = [tokensFile UTF8String];
        config.model.kitten.data_dir = [dataDir UTF8String];

    } else if ([modelType isEqualToString:@"vits"]) {
        NSString *modelFile = [modelPath stringByAppendingPathComponent:@"model.onnx"];
        NSString *tokensFile = [modelPath stringByAppendingPathComponent:@"tokens.txt"];
        NSString *lexiconFile = [modelPath stringByAppendingPathComponent:@"lexicon.txt"];
        NSString *dataDir = [modelPath stringByAppendingPathComponent:@"espeak-ng-data"];

        config.model.vits.model = [modelFile UTF8String];
        config.model.vits.tokens = [tokensFile UTF8String];
        config.model.vits.lexicon = [lexiconFile UTF8String];
        config.model.vits.data_dir = [dataDir UTF8String];
        config.model.vits.length_scale = 1.0;
        config.model.vits.noise_scale = 0.667;
        config.model.vits.noise_scale_w = 0.8;

    } else if ([modelType isEqualToString:@"kokoro"]) {
        NSString *modelFile = [modelPath stringByAppendingPathComponent:@"model.onnx"];
        NSString *voicesFile = [modelPath stringByAppendingPathComponent:@"voices.bin"];
        NSString *tokensFile = [modelPath stringByAppendingPathComponent:@"tokens.txt"];

        config.model.kokoro.model = [modelFile UTF8String];
        config.model.kokoro.voices = [voicesFile UTF8String];
        config.model.kokoro.tokens = [tokensFile UTF8String];
        config.model.kokoro.length_scale = 1.0;

    } else if ([modelType isEqualToString:@"matcha"]) {
        NSString *acousticModelFile = [modelPath stringByAppendingPathComponent:@"model.onnx"];
        NSString *vocoderFile = [modelPath stringByAppendingPathComponent:@"vocoder.onnx"];
        NSString *tokensFile = [modelPath stringByAppendingPathComponent:@"tokens.txt"];
        NSString *dataDir = [modelPath stringByAppendingPathComponent:@"espeak-ng-data"];

        config.model.matcha.acoustic_model = [acousticModelFile UTF8String];
        config.model.matcha.vocoder = [vocoderFile UTF8String];
        config.model.matcha.tokens = [tokensFile UTF8String];
        config.model.matcha.data_dir = [dataDir UTF8String];
        config.model.matcha.length_scale = 1.0;
        config.model.matcha.noise_scale = 0.667;
        config.model.matcha.noise_scale_w = 0.8;

    } else {
        NSLog(@"[SherpaONNXBridge] Unknown model type: %@", modelType);
        return NO;
    }

    // Create TTS instance
    tts = SherpaOnnxCreateOfflineTts(&config);
    if (!tts) {
        NSLog(@"[SherpaONNXBridge] Failed to create TTS instance");
        return NO;
    }

    // Get TTS properties
    _sampleRate = SherpaOnnxOfflineTtsSampleRate(tts);
    _numSpeakers = SherpaOnnxOfflineTtsNumSpeakers(tts);

    NSLog(@"[SherpaONNXBridge] TTS initialized with sample rate: %d, speakers: %d",
          _sampleRate, _numSpeakers);

    return YES;
#else
    NSLog(@"[SherpaONNXBridge] Sherpa-ONNX framework not available. Please build XCFrameworks first.");
    return NO;
#endif
}

#pragma mark - Synthesis

- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed {

    if (!tts || !text || text.length == 0) {
        return nil;
    }

#ifdef SHERPA_ONNX_AVAILABLE
    // Validate speaker ID
    if (speakerId < 0 || speakerId >= _numSpeakers) {
        NSLog(@"[SherpaONNXBridge] Invalid speaker ID: %ld (max: %d)",
              (long)speakerId, _numSpeakers - 1);
        speakerId = 0; // Default to first speaker
    }

    // Generate audio
    const SherpaOnnxGeneratedAudio *audio = SherpaOnnxOfflineTtsGenerate(
        tts,
        [text UTF8String],
        (int32_t)speakerId,
        speed
    );

    if (!audio || !audio->samples || audio->n == 0) {
        NSLog(@"[SherpaONNXBridge] Failed to generate audio for text: %@", text);
        if (audio) {
            SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio);
        }
        return nil;
    }

    // Convert float samples to NSData
    NSData *audioData = [NSData dataWithBytes:audio->samples
                                        length:audio->n * sizeof(float)];

    // Free the generated audio
    SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio);

    return audioData;
#else
    // Return mock data when framework not available
    NSLog(@"[SherpaONNXBridge] Returning mock audio data (framework not available)");

    // Generate simple sine wave for testing
    float frequency = 440.0; // A4 note
    float amplitude = 0.1;
    int sampleRate = 16000;
    float duration = 1.0; // 1 second of audio
    int numSamples = (int)(duration * sampleRate);

    NSMutableData *mockData = [NSMutableData dataWithCapacity:numSamples * sizeof(float)];
    for (int i = 0; i < numSamples; i++) {
        float time = (float)i / sampleRate;
        float sample = amplitude * sinf(2.0 * M_PI * frequency * time);
        [mockData appendBytes:&sample length:sizeof(float)];
    }

    return mockData;
#endif
}

- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed
                            progress:(nullable void (^)(float))progressBlock {

    if (!tts || !text || text.length == 0) {
        return nil;
    }

#ifdef SHERPA_ONNX_AVAILABLE
    // For progress callbacks, we need to use the callback-based API
    // This is a simplified version - full implementation would use
    // SherpaOnnxOfflineTtsGenerateWithProgressCallback

    // For now, just call the regular synthesis and report progress
    if (progressBlock) {
        progressBlock(0.0);
    }

    NSData *result = [self synthesizeText:text speakerId:speakerId speed:speed];

    if (progressBlock) {
        progressBlock(1.0);
    }

    return result;
#else
    // Fallback to regular synthesis
    return [self synthesizeText:text speakerId:speakerId speed:speed];
#endif
}

#pragma mark - Properties

- (NSInteger)numberOfSpeakers {
#ifdef SHERPA_ONNX_AVAILABLE
    return tts ? _numSpeakers : 0;
#else
    return 1; // Mock: return 1 speaker
#endif
}

- (NSInteger)sampleRate {
#ifdef SHERPA_ONNX_AVAILABLE
    return tts ? _sampleRate : 16000;
#else
    return 16000; // Mock: return standard sample rate
#endif
}

- (BOOL)isValidSpeaker:(NSInteger)speakerId {
    return speakerId >= 0 && speakerId < [self numberOfSpeakers];
}

- (nullable NSString *)speakerNameForId:(NSInteger)speakerId {
    if (![self isValidSpeaker:speakerId]) {
        return nil;
    }

    // Sherpa-ONNX doesn't provide speaker names directly
    // We'll generate descriptive names based on the model
    return [NSString stringWithFormat:@"Speaker %ld", (long)(speakerId + 1)];
}

#pragma mark - Cleanup

- (void)destroy {
#ifdef SHERPA_ONNX_AVAILABLE
    if (tts) {
        SherpaOnnxDestroyOfflineTts(tts);
        tts = nullptr;
    }
#endif
}

- (void)dealloc {
    [self destroy];
}

@end
