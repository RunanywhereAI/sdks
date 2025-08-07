import Foundation
import SwiftUI

// MARK: - Analytics APIs

extension RunAnywhereSDK {
    
    /// Access to the generation analytics service
    public var generationAnalytics: GenerationAnalyticsService {
        serviceContainer.generationAnalytics
    }
    
    /// Get analytics session by ID
    /// - Parameter sessionId: The session ID to look up
    /// - Returns: The generation session if found
    public func getAnalyticsSession(_ sessionId: UUID) async -> GenerationSession? {
        return await generationAnalytics.getSession(sessionId)
    }
    
    /// Get all analytics sessions
    /// - Returns: Array of all generation sessions
    public func getAllAnalyticsSessions() async -> [GenerationSession] {
        return await generationAnalytics.getAllSessions()
    }
    
    /// Get session summary with aggregated metrics
    /// - Parameter sessionId: The session ID
    /// - Returns: Session summary with aggregated metrics
    public func getSessionSummary(_ sessionId: UUID) async -> SessionSummary? {
        return await generationAnalytics.getSessionSummary(sessionId)
    }
    
    /// Get average metrics for a specific model
    /// - Parameters:
    ///   - modelId: The model ID to get metrics for
    ///   - limit: Maximum number of recent sessions to consider
    /// - Returns: Average metrics across sessions
    public func getAverageMetrics(for modelId: String, limit: Int = 10) async -> AverageMetrics? {
        return await generationAnalytics.getAverageMetrics(for: modelId, limit: limit)
    }
    
    /// Observe live metrics for a specific generation
    /// - Parameter generationId: The generation ID to observe
    /// - Returns: Async stream of live generation metrics
    public func observeLiveMetrics(for generationId: UUID) -> AsyncStream<LiveGenerationMetrics> {
        return generationAnalytics.observeLiveMetrics(for: generationId)
    }
    
    /// Get generations for a specific session
    /// - Parameter sessionId: The session ID
    /// - Returns: Array of generations in the session
    public func getGenerations(for sessionId: UUID) async -> [Generation] {
        return await generationAnalytics.getGenerations(for: sessionId)
    }
    
    /// Get currently active analytics sessions
    /// - Returns: Array of active generation sessions
    public func getActiveAnalyticsSessions() async -> [GenerationSession] {
        return await generationAnalytics.getActiveSessions()
    }
    
    /// Get the current session ID if any is active
    /// - Returns: Current session ID or nil
    public func getCurrentSessionId() async -> UUID? {
        return await generationAnalytics.getCurrentSessionId()
    }
    
    /// Start a new analytics session
    /// - Parameters:
    ///   - modelId: The model ID for the session
    ///   - type: The type of session (chat, document, etc.)
    /// - Returns: The created generation session
    public func startAnalyticsSession(modelId: String, type: SessionType) async -> GenerationSession {
        return await generationAnalytics.startSession(modelId: modelId, type: type)
    }
    
    /// End an analytics session
    /// - Parameter sessionId: The session ID to end
    public func endAnalyticsSession(_ sessionId: UUID) async {
        await generationAnalytics.endSession(sessionId)
    }
}

// MARK: - Analytics UI

@available(iOS 14.0, macOS 11.0, *)
extension RunAnywhereSDK {
    
    /// Create an analytics view for displaying session and generation analytics
    /// - Returns: SwiftUI view that displays comprehensive analytics
    public func createAnalyticsView() -> some View {
        AnalyticsView()
    }
    
    /// Create a simple analytics summary view
    /// - Returns: SwiftUI view with basic analytics summary
    public func createAnalyticsSummaryView() -> some View {
        AnalyticsSummaryView()
    }
}

// MARK: - Simple Analytics Summary View

@available(iOS 14.0, macOS 11.0, *)
struct AnalyticsSummaryView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Analytics Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.allSessions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.totalGenerations)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Generations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(viewModel.formattedTokenCount(viewModel.totalTokens))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let mostActiveModel = viewModel.mostActiveModel {
                Text("Most Used: \(mostActiveModel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .task {
            await viewModel.loadData()
        }
    }
}