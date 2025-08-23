import Foundation
import AVFoundation
import RunAnywhereSDK
import SherpaONNXBridge
import os

/// Wrapper for Sherpa-ONNX native TTS engine
/// This bridges Swift code with the C++ Sherpa-ONNX implementation
final class SherpaONNXWrapper {

    // MARK: - Properties

    private let configuration: SherpaONNXConfiguration
    private var bridge: SherpaONNXBridge?
    private var isRunning = false

    private let queue = DispatchQueue(label: "com.runanywhere.sherpaonnx.wrapper")
    private let logger = Logger(
        subsystem: "com.runanywhere.sdk",
        category: "SherpaONNXWrapper"
    )

    // Voice management
    private var voices: [VoiceInfo] = []
    private var selectedVoiceId: String?

    // MARK: - Computed Properties

    var availableVoices: [VoiceInfo] {
        return voices
    }

    var currentVoice: VoiceInfo? {
        guard let voiceId = selectedVoiceId else { return nil }
        return voices.first { $0.id == voiceId }
    }

    var sampleRate: Int {
        return bridge?.sampleRate() ?? 16000
    }

    var numberOfSpeakers: Int {
        return bridge?.numberOfSpeakers() ?? 1
    }

    // MARK: - Initialization

    init(configuration: SherpaONNXConfiguration) async throws {
        self.configuration = configuration

        // Initialize the native bridge
        try await initializeBridge()

        // Initialize voices based on the bridge capabilities
        await initializeVoices()

        logger.info("SherpaONNXWrapper initialized with model type: \(configuration.modelType.rawValue)")
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods

    /// Synthesize text to audio data
    func synthesize(
        text: String,
        rate: Float,
        pitch: Float,
        volume: Float
    ) async throws -> Data {
        guard let bridge = bridge else {
            throw SherpaONNXError.notInitialized
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    // Use the selected voice ID or default to 0
                    let speakerId = self.getSpeakerId(for: self.selectedVoiceId)

                    // Call native Sherpa-ONNX synthesis through bridge
                    guard let audioData = bridge.synthesizeText(
                        text,
                        speakerId: speakerId,
                        speed: rate
                    ) else {
                        throw SherpaONNXError.synthesisFailure("Failed to generate audio")
                    }

                    continuation.resume(returning: audioData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Stream synthesis for real-time generation
    func synthesizeStream(
        text: String,
        rate: Float,
        pitch: Float,
        volume: Float
    ) -> AsyncThrowingStream<Data, Error> {

        AsyncThrowingStream { continuation in
            queue.async {
                guard let bridge = self.bridge else {
                    continuation.finish(throwing: SherpaONNXError.notInitialized)
                    return
                }

                do {
                    let speakerId = self.getSpeakerId(for: self.selectedVoiceId)

                    // Use the progress-based synthesis for streaming
                    guard let audioData = bridge.synthesizeText(
                        text,
                        speakerId: speakerId,
                        speed: rate,
                        progress: { progress in
                            // Could yield partial data here if bridge supported it
                        }
                    ) else {
                        continuation.finish(throwing: SherpaONNXError.synthesisFailure("Failed to generate audio"))
                        return
                    }

                    // For now, chunk the full audio data
                    let chunkSize = 16000 * MemoryLayout<Float>.size // ~1 second at 16kHz

                    var offset = 0
                    while offset < audioData.count {
                        let endIndex = min(offset + chunkSize, audioData.count)
                        let chunk = audioData.subdata(in: offset..<endIndex)
                        continuation.yield(chunk)
                        offset = endIndex

                        // Small delay to simulate real-time streaming
                        Thread.sleep(forTimeInterval: 0.1)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Set the active voice
    func setVoice(_ voiceIdentifier: String) async throws {
        guard voices.contains(where: { $0.id == voiceIdentifier }) else {
            throw SherpaONNXError.voiceNotFound(voiceIdentifier)
        }

        selectedVoiceId = voiceIdentifier

        // TODO: Set voice in native engine
        logger.debug("Voice set to: \(voiceIdentifier)")
    }

    /// Stop synthesis
    func stop() {
        queue.async {
            self.isRunning = false
            // TODO: Stop native synthesis
        }
    }

    /// Pause synthesis
    func pause() {
        // TODO: Implement pause in native engine
        logger.debug("Synthesis paused")
    }

    /// Resume synthesis
    func resume() {
        // TODO: Implement resume in native engine
        logger.debug("Synthesis resumed")
    }

    /// Clean up resources
    func cleanup() {
        queue.sync {
            bridge?.destroy()
            bridge = nil
        }
        logger.debug("Wrapper cleaned up")
    }

    // MARK: - Private Methods

    /// Initialize the native bridge
    private func initializeBridge() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    // Create the bridge with configuration
                    let bridge = SherpaONNXBridge(
                        modelPath: self.configuration.modelPath.path,
                        modelType: self.configuration.modelType.rawValue,
                        numThreads: self.configuration.numThreads,
                        maxSentenceLength: self.configuration.maxSentenceLength
                    )

                    guard bridge != nil else {
                        throw SherpaONNXError.notInitialized
                    }

                    self.bridge = bridge
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Initialize voices based on bridge capabilities
    private func initializeVoices() async {
        guard let bridge = bridge else {
            // Fallback to mock voices if bridge not available
            await initializeMockVoices()
            return
        }

        let numSpeakers = bridge.numberOfSpeakers
        voices = []

        // Create voice entries based on model type and speaker count
        for speakerId in 0..<numSpeakers() {
            let voiceName = bridge.speakerName(forId: speakerId) ?? "Speaker \(speakerId + 1)"
            let voice = VoiceInfo(
                id: "speaker-\(speakerId)",
                name: voiceName,
                language: getLanguageForModelType(configuration.modelType),
                gender: .neutral // Default to neutral since we don't have gender info from bridge
            )
            voices.append(voice)
        }

        // Select first voice by default
        selectedVoiceId = voices.first?.id
    }

    /// Initialize mock voices for testing when bridge is not available
    private func initializeMockVoices() async {
        switch configuration.modelType {
        case .kitten:
            voices = createKittenVoices()
        case .kokoro:
            voices = createKokoroVoices()
        case .vits:
            voices = createVITSVoices()
        case .matcha:
            voices = createMatchaVoices()
        case .piper:
            voices = createPiperVoices()
        }

        // Select first voice by default
        selectedVoiceId = voices.first?.id
    }

    /// Get speaker ID for a voice identifier
    private func getSpeakerId(for voiceId: String?) -> Int {
        guard let voiceId = voiceId,
              voiceId.hasPrefix("speaker-"),
              let speakerId = Int(String(voiceId.dropFirst("speaker-".count))) else {
            return 0 // Default to first speaker
        }
        return speakerId
    }

    /// Get default language for model type
    private func getLanguageForModelType(_ modelType: SherpaONNXModelType) -> String {
        switch modelType {
        case .kitten, .vits, .matcha, .piper:
            return "en-US"
        case .kokoro:
            return "en-US" // Kokoro supports multiple languages
        }
    }

    private func createKittenVoices() -> [VoiceInfo] {
        return [
            VoiceInfo(id: "expr-voice-1-f", name: "Expressive Female 1", language: "en-US", gender: .female),
            VoiceInfo(id: "expr-voice-2-f", name: "Expressive Female 2", language: "en-US", gender: .female),
            VoiceInfo(id: "expr-voice-3-m", name: "Expressive Male 1", language: "en-US", gender: .male),
            VoiceInfo(id: "expr-voice-4-m", name: "Expressive Male 2", language: "en-US", gender: .male),
            VoiceInfo(id: "neutral-voice-1-f", name: "Neutral Female", language: "en-US", gender: .female),
            VoiceInfo(id: "neutral-voice-2-m", name: "Neutral Male", language: "en-US", gender: .male),
            VoiceInfo(id: "happy-voice-f", name: "Happy Female", language: "en-US", gender: .female),
            VoiceInfo(id: "calm-voice-m", name: "Calm Male", language: "en-US", gender: .male)
        ]
    }

    private func createKokoroVoices() -> [VoiceInfo] {
        return [
            VoiceInfo(id: "kokoro-en-f-1", name: "Kokoro English Female 1", language: "en-US", gender: .female),
            VoiceInfo(id: "kokoro-en-m-1", name: "Kokoro English Male 1", language: "en-US", gender: .male),
            VoiceInfo(id: "kokoro-en-f-2", name: "Kokoro English Female 2", language: "en-US", gender: .female),
            VoiceInfo(id: "kokoro-es-f", name: "Kokoro Spanish Female", language: "es-ES", gender: .female),
            VoiceInfo(id: "kokoro-fr-f", name: "Kokoro French Female", language: "fr-FR", gender: .female),
            VoiceInfo(id: "kokoro-de-m", name: "Kokoro German Male", language: "de-DE", gender: .male)
        ]
    }

    private func createVITSVoices() -> [VoiceInfo] {
        return [
            VoiceInfo(id: "vits-lessac", name: "VITS Lessac", language: "en-US", gender: .neutral)
        ]
    }

    private func createMatchaVoices() -> [VoiceInfo] {
        return [
            VoiceInfo(id: "matcha-default", name: "Matcha Default", language: "en-US", gender: .neutral),
            VoiceInfo(id: "matcha-expressive", name: "Matcha Expressive", language: "en-US", gender: .neutral)
        ]
    }

    private func createPiperVoices() -> [VoiceInfo] {
        return [
            VoiceInfo(id: "piper-amy", name: "Amy", language: "en-US", gender: .female),
            VoiceInfo(id: "piper-ryan", name: "Ryan", language: "en-US", gender: .male)
        ]
    }

}
