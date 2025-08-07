import Foundation
import SwiftUI
import RunAnywhereSDK

// MARK: - SDK Analytics Adapter

/// Adapter that bridges sample app analytics needs with SDK analytics capabilities
@MainActor
class AnalyticsAdapter: ObservableObject {
    static let shared = AnalyticsAdapter()
    
    private let sdk = RunAnywhereSDK.shared
    private var currentSessionId: UUID?
    
    // Published properties for UI binding
    @Published var currentSession: GenerationSession?
    @Published var allSessions: [GenerationSession] = []
    @Published var sessionSummary: SessionSummary?
    
    private init() {
        // Load existing sessions on initialization
        Task {
            await loadSessions()
        }
    }
    
    // MARK: - Session Management
    
    /// Start a new conversation session
    func startConversationSession(modelId: String) async -> UUID {
        let session = await sdk.startAnalyticsSession(modelId: modelId, type: .chat)
        currentSessionId = session.id
        currentSession = session
        await loadSessions()
        return session.id
    }
    
    /// End the current session
    func endCurrentSession() async {
        guard let sessionId = currentSessionId else { return }
        await sdk.endAnalyticsSession(sessionId)
        currentSessionId = nil
        currentSession = nil
        await loadSessions()
    }
    
    /// Get the current session ID
    func getCurrentSessionId() -> UUID? {
        return currentSessionId
    }
    
    // MARK: - Analytics Data Access
    
    /// Load all sessions for display
    func loadSessions() async {
        allSessions = await sdk.getAllAnalyticsSessions()
        
        // Update current session if we have one
        if let sessionId = currentSessionId {
            currentSession = await sdk.getAnalyticsSession(sessionId)
            sessionSummary = await sdk.getSessionSummary(sessionId)
        }
    }
    
    /// Get generations for a specific session
    func getGenerations(for sessionId: UUID) async -> [Generation] {
        return await sdk.getGenerations(for: sessionId)
    }
    
    /// Get session summary
    func getSessionSummary(for sessionId: UUID) async -> SessionSummary? {
        return await sdk.getSessionSummary(sessionId)
    }
    
    /// Observe live metrics for a generation
    func observeLiveMetrics(for generationId: UUID) -> AsyncStream<LiveGenerationMetrics> {
        return sdk.observeLiveMetrics(for: generationId)
    }
    
    // MARK: - Analytics Conversion Helpers
    
    /// Convert SDK Generation to sample app MessageAnalytics format (for backward compatibility)
    func convertToMessageAnalytics(_ generation: Generation, conversation: Conversation?) -> MessageAnalytics? {
        guard let performance = generation.performance else { return nil }
        guard let conversation = conversation else { return nil }
        
        return MessageAnalytics(
            messageId: generation.id.uuidString,
            conversationId: conversation.id,
            modelId: performance.modelId,
            modelName: performance.modelId, // Using ID as name for now
            framework: performance.routingFramework ?? "unknown",
            timestamp: generation.timestamp,
            timeToFirstToken: performance.timeToFirstToken,
            totalGenerationTime: performance.totalGenerationTime,
            thinkingTime: nil, // Not tracked separately in SDK
            responseTime: performance.totalGenerationTime,
            inputTokens: performance.inputTokens,
            outputTokens: performance.outputTokens,
            thinkingTokens: nil, // Not separated in SDK
            responseTokens: performance.outputTokens,
            averageTokensPerSecond: performance.tokensPerSecond,
            messageLength: performance.outputTokens * 4, // Rough estimation
            wasThinkingMode: false, // Would need to be tracked separately
            wasInterrupted: false, // Would need to be tracked separately
            retryCount: 0,
            completionStatus: .complete, // Would need more detailed tracking
            tokensPerSecondHistory: [], // Not available in SDK currently
            generationMode: .streaming, // Default assumption
            contextWindowUsage: 0.0, // Not tracked in SDK
            generationParameters: MessageAnalytics.GenerationParameters()
        )
    }
    
    /// Convert SDK GenerationSession to sample app ConversationAnalytics format
    func convertToConversationAnalytics(_ session: GenerationSession, summary: SessionSummary?) -> ConversationAnalytics? {
        guard let summary = summary else { return nil }
        
        let modelsUsed = Set([session.modelId])
        
        return ConversationAnalytics(
            conversationId: session.id.uuidString,
            startTime: session.startTime,
            endTime: session.endTime,
            messageCount: summary.totalGenerations,
            averageTTFT: summary.averageTimeToFirstToken,
            averageGenerationSpeed: summary.averageTokensPerSecond,
            totalTokensUsed: summary.totalInputTokens + summary.totalOutputTokens,
            modelsUsed: modelsUsed,
            thinkingModeUsage: 0.0, // Not tracked in SDK
            completionRate: 1.0, // Assume all complete for now
            averageMessageLength: summary.totalOutputTokens / max(summary.totalGenerations, 1),
            currentModel: session.modelId,
            ongoingMetrics: nil
        )
    }
    
    // MARK: - Performance Helpers
    
    /// Get average metrics for the current model
    func getAverageMetrics(for modelId: String) async -> AverageMetrics? {
        return await sdk.getAverageMetrics(for: modelId)
    }
    
    /// Get performance summary for display
    func getPerformanceSummary(for sessionId: UUID) async -> PerformanceSummary? {
        guard let summary = await sdk.getSessionSummary(sessionId) else { return nil }
        guard let session = await sdk.getAnalyticsSession(sessionId) else { return nil }
        
        return PerformanceSummary(
            averageResponseTime: summary.totalDuration / Double(max(summary.totalGenerations, 1)),
            totalTokens: summary.totalInputTokens + summary.totalOutputTokens,
            mainModel: session.modelId,
            completionRate: 1.0, // Assume all complete
            averageTokensPerSecond: summary.averageTokensPerSecond
        )
    }
}

// MARK: - Legacy Analytics Models for Backward Compatibility

/// Simplified version of the original MessageAnalytics for compatibility
struct MessageAnalytics: Codable {
    // Identifiers
    let messageId: String
    let conversationId: String
    let modelId: String
    let modelName: String
    let framework: String
    let timestamp: Date

    // Timing Metrics
    let timeToFirstToken: TimeInterval?
    let totalGenerationTime: TimeInterval
    let thinkingTime: TimeInterval?
    let responseTime: TimeInterval?

    // Token Metrics
    let inputTokens: Int
    let outputTokens: Int
    let thinkingTokens: Int?
    let responseTokens: Int
    let averageTokensPerSecond: Double

    // Quality Metrics
    let messageLength: Int
    let wasThinkingMode: Bool
    let wasInterrupted: Bool
    let retryCount: Int
    let completionStatus: CompletionStatus

    // Performance Indicators
    let tokensPerSecondHistory: [Double]
    let generationMode: GenerationMode

    // Context Information
    let contextWindowUsage: Double
    let generationParameters: GenerationParameters

    enum CompletionStatus: String, Codable {
        case complete
        case interrupted
        case failed
        case timeout
    }

    enum GenerationMode: String, Codable {
        case streaming
        case nonStreaming
    }

    struct GenerationParameters: Codable {
        let temperature: Double
        let maxTokens: Int
        let topP: Double?
        let topK: Int?

        init(temperature: Double = 0.7, maxTokens: Int = 500, topP: Double? = nil, topK: Int? = nil) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
            self.topK = topK
        }
    }
}

/// Simplified ConversationAnalytics for compatibility
struct ConversationAnalytics: Codable {
    let conversationId: String
    let startTime: Date
    let endTime: Date?
    let messageCount: Int

    // Aggregate Metrics
    let averageTTFT: TimeInterval
    let averageGenerationSpeed: Double
    let totalTokensUsed: Int
    let modelsUsed: Set<String>

    // Efficiency Metrics
    let thinkingModeUsage: Double
    let completionRate: Double
    let averageMessageLength: Int

    // Real-time Metrics
    let currentModel: String?
    let ongoingMetrics: MessageAnalytics?
}