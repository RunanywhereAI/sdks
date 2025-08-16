import Foundation
import SwiftUI

// MARK: - Analytics View Model

/// ViewModel for the SDK Analytics View
@available(iOS 14.0, macOS 11.0, *)
@MainActor
class AnalyticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allSessions: [GenerationSession] = []
    @Published var activeSessions: [GenerationSession] = []
    @Published var selectedSession: GenerationSession?
    @Published var selectedSessionSummary: SessionSummary?
    @Published var selectedSessionGenerations: [Generation] = []
    @Published var modelMetrics: [String: AverageMetrics] = [:]
    
    // Live metrics
    @Published var currentGeneration: Generation?
    @Published var currentLiveMetrics: LiveGenerationMetrics?
    
    // Loading states
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let sdk = RunAnywhereSDK.shared
    private var liveMetricsTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        // Start observing for live generation updates
        startLiveMetricsObservation()
    }
    
    deinit {
        liveMetricsTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load all analytics data
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load sessions
            await loadSessions()
            
            // Load model metrics
            await loadModelMetrics()
            
        } catch {
            errorMessage = "Failed to load analytics data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Refresh all data
    func refresh() async {
        await loadData()
    }
    
    /// Select a session for detailed analysis
    func selectSession(_ sessionId: UUID) async {
        // Find the session
        guard let session = allSessions.first(where: { $0.id == sessionId }) else {
            return
        }
        
        selectedSession = session
        
        // Load session details
        selectedSessionSummary = await sdk.getSessionSummary(sessionId)
        selectedSessionGenerations = await sdk.getGenerations(for: sessionId)
    }
    
    /// Clear selected session
    func clearSelection() {
        selectedSession = nil
        selectedSessionSummary = nil
        selectedSessionGenerations = []
    }
    
    // MARK: - Private Methods
    
    /// Load all sessions
    private func loadSessions() async {
        allSessions = await sdk.getAllAnalyticsSessions()
        activeSessions = await sdk.getActiveAnalyticsSessions()
    }
    
    /// Load model metrics for comparison
    private func loadModelMetrics() async {
        // Get unique model IDs from sessions
        let modelIds = Set(allSessions.map { $0.modelId })
        
        var metrics: [String: AverageMetrics] = [:]
        
        for modelId in modelIds {
            if let modelAverage = await sdk.getAverageMetrics(for: modelId) {
                metrics[modelId] = modelAverage
            }
        }
        
        modelMetrics = metrics
    }
    
    /// Start observing live metrics for any active generation
    private func startLiveMetricsObservation() {
        liveMetricsTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkForLiveGeneration()
                
                // Check every second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    /// Check for active generation and observe its live metrics
    private func checkForLiveGeneration() async {
        // Get current session ID
        guard let currentSessionId = await sdk.getCurrentSessionId() else {
            // No active session, clear live metrics
            currentGeneration = nil
            currentLiveMetrics = nil
            return
        }
        
        // Get generations for current session
        let generations = await sdk.getGenerations(for: currentSessionId)
        
        // Find the most recent generation that might be active
        guard let latestGeneration = generations.last else {
            currentGeneration = nil
            currentLiveMetrics = nil
            return
        }
        
        // Check if this generation has completed performance data
        if latestGeneration.performance != nil {
            // Generation is complete, clear live metrics
            currentGeneration = nil
            currentLiveMetrics = nil
            return
        }
        
        // This generation might be active, try to get live metrics
        currentGeneration = latestGeneration
        
        // Observe live metrics for this generation
        observeLiveMetricsForGeneration(latestGeneration.id)
    }
    
    /// Observe live metrics for a specific generation
    private func observeLiveMetricsForGeneration(_ generationId: UUID) {
        // Cancel any existing observation
        liveMetricsTask?.cancel()
        
        liveMetricsTask = Task { [weak self] in
            let metricsStream = self?.sdk.observeLiveMetrics(for: generationId)
            
            guard let stream = metricsStream else { return }
            
            for await metrics in stream {
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    self?.currentLiveMetrics = metrics
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension AnalyticsViewModel {
    
    /// Get formatted session duration
    func formattedDuration(for session: GenerationSession) -> String {
        if let endTime = session.endTime {
            let duration = endTime.timeIntervalSince(session.startTime)
            return String(format: "%.1fs", duration)
        } else {
            let duration = Date().timeIntervalSince(session.startTime)
            return String(format: "%.1fs (ongoing)", duration)
        }
    }
    
    /// Get session status string
    func sessionStatus(for session: GenerationSession) -> String {
        return session.endTime != nil ? "Completed" : "Active"
    }
    
    /// Get session status color
    func sessionStatusColor(for session: GenerationSession) -> Color {
        return session.endTime != nil ? .green : .blue
    }
    
    /// Format token count with appropriate units
    func formattedTokenCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK", thousands)
        } else {
            return "\(count)"
        }
    }
    
    /// Format speed with appropriate precision
    func formattedSpeed(_ tokensPerSecond: Double) -> String {
        if tokensPerSecond >= 100 {
            return String(format: "%.0f", tokensPerSecond)
        } else if tokensPerSecond >= 10 {
            return String(format: "%.1f", tokensPerSecond)
        } else {
            return String(format: "%.2f", tokensPerSecond)
        }
    }
    
    /// Get the most active model ID
    var mostActiveModel: String? {
        guard !allSessions.isEmpty else { return nil }
        
        let modelCounts = Dictionary(grouping: allSessions, by: { $0.modelId })
            .mapValues { $0.count }
        
        return modelCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Get total generations across all sessions
    var totalGenerations: Int {
        return allSessions.reduce(0) { $0 + $1.generationCount }
    }
    
    /// Get total tokens across all sessions
    var totalTokens: Int {
        return allSessions.reduce(0) { $0 + $1.totalInputTokens + $1.totalOutputTokens }
    }
    
    /// Get average session duration
    var averageSessionDuration: TimeInterval {
        let completedSessions = allSessions.filter { $0.endTime != nil }
        guard !completedSessions.isEmpty else { return 0 }
        
        let totalDuration = completedSessions.reduce(0.0) { $0 + $1.totalDuration }
        return totalDuration / Double(completedSessions.count)
    }
}