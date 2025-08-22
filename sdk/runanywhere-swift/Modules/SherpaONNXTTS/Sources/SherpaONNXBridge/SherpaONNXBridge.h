//
//  SherpaONNXBridge.h
//  SherpaONNXTTS
//
//  Objective-C++ bridge for Sherpa-ONNX C API
//

#ifndef SherpaONNXBridge_h
#define SherpaONNXBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SherpaONNXBridge : NSObject

/// Initialize TTS with model configuration
/// @param modelPath Path to the model directory
/// @param modelType Type of model (kitten, vits, kokoro, matcha)
/// @param numThreads Number of threads for inference
/// @param maxSentenceLength Maximum sentence length for chunking
- (nullable instancetype)initWithModelPath:(NSString *)modelPath
                                  modelType:(NSString *)modelType
                                 numThreads:(NSInteger)numThreads
                          maxSentenceLength:(NSInteger)maxSentenceLength;

/// Synthesize text to audio
/// @param text Text to synthesize
/// @param speakerId Speaker/voice ID (0-based)
/// @param speed Speech speed (1.0 = normal)
/// @return Audio data as Float32 PCM samples, or nil on failure
- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed;

/// Synthesize text with progress callback
/// @param text Text to synthesize
/// @param speakerId Speaker/voice ID
/// @param speed Speech speed
/// @param progressBlock Progress callback (0.0 to 1.0)
/// @return Audio data or nil
- (nullable NSData *)synthesizeText:(NSString *)text
                           speakerId:(NSInteger)speakerId
                               speed:(float)speed
                            progress:(nullable void (^)(float progress))progressBlock;

/// Get number of available speakers/voices
- (NSInteger)numberOfSpeakers;

/// Get the sample rate of generated audio
- (NSInteger)sampleRate;

/// Check if a specific speaker ID is valid
- (BOOL)isValidSpeaker:(NSInteger)speakerId;

/// Get speaker name if available
- (nullable NSString *)speakerNameForId:(NSInteger)speakerId;

/// Clean up and release resources
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

#endif /* SherpaONNXBridge_h */
