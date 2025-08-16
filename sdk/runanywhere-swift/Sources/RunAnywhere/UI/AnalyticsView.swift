import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - SDK Analytics UI Components

/// Main analytics view that displays session and generation analytics
@available(iOS 14.0, macOS 11.0, *)
public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Sessions Overview
                SessionsOverviewView(viewModel: viewModel)
                    .tabItem {
                        Label("Sessions", systemImage: "chart.bar.doc.horizontal")
                    }
                    .tag(0)
                
                // Live Metrics
                LiveMetricsView(viewModel: viewModel)
                    .tabItem {
                        Label("Live", systemImage: "waveform.path.ecg")
                    }
                    .tag(1)
                
                // Performance Analysis
                PerformanceAnalysisView(viewModel: viewModel)
                    .tabItem {
                        Label("Performance", systemImage: "speedometer")
                    }
                    .tag(2)
                
                // Model Comparison
                ModelComparisonView(viewModel: viewModel)
                    .tabItem {
                        Label("Models", systemImage: "cube.box")
                    }
                    .tag(3)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Sessions Overview View

@available(iOS 14.0, macOS 11.0, *)
struct SessionsOverviewView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Cards
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Sessions",
                        value: "\(viewModel.allSessions.count)",
                        icon: "chart.bar.doc.horizontal",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Active Sessions",
                        value: "\(viewModel.activeSessions.count)",
                        icon: "play.circle",
                        color: .green
                    )
                }
                
                // Sessions List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.allSessions.prefix(10), id: \.id) { session in
                        SessionRowView(session: session) {
                            await viewModel.selectSession(session.id)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Session Row View

@available(iOS 14.0, macOS 11.0, *)
struct SessionRowView: View {
    let session: GenerationSession
    let onTap: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.modelId)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(session.sessionType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if session.endTime != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            
            // Session metrics
            HStack(spacing: 16) {
                MetricChip(
                    label: "Generations",
                    value: "\(session.generationCount)",
                    color: .blue
                )
                
                if session.averageTokensPerSecond > 0 {
                    MetricChip(
                        label: "Avg Speed",
                        value: String(format: "%.1f tok/s", session.averageTokensPerSecond),
                        color: .green
                    )
                }
                
                if session.totalDuration > 0 {
                    MetricChip(
                        label: "Duration",
                        value: String(format: "%.1fs", session.totalDuration),
                        color: .orange
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .onTapGesture {
            Task {
                await onTap()
            }
        }
    }
}

// MARK: - Live Metrics View

@available(iOS 14.0, macOS 11.0, *)
struct LiveMetricsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let currentGeneration = viewModel.currentGeneration,
                   let liveMetrics = viewModel.currentLiveMetrics {
                    
                    // Live generation in progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Live Generation")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LiveGenerationCard(
                            generation: currentGeneration,
                            metrics: liveMetrics
                        )
                    }
                    .padding()
                    
                } else {
                    // No active generation
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("No Active Generation")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Live metrics will appear here during text generation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Live Generation Card

@available(iOS 14.0, macOS 11.0, *)
struct LiveGenerationCard: View {
    let generation: Generation
    let metrics: LiveGenerationMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generation \(generation.sequenceNumber)")
                    .font(.headline)
                
                Spacer()
                
                Text("LIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
            
            // Real-time metrics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Elapsed Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1fs", metrics.elapsedTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tokens Generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(metrics.tokensGenerated)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f tok/s", metrics.currentTokensPerSecond))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            
            if let ttft = metrics.timeToFirstToken {
                HStack {
                    Text("Time to First Token:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3fs", ttft))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Performance Analysis View

@available(iOS 14.0, macOS 11.0, *)
struct PerformanceAnalysisView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let selectedSession = viewModel.selectedSession,
                   let sessionSummary = viewModel.selectedSessionSummary {
                    
                    // Session details
                    SessionDetailCard(session: selectedSession, summary: sessionSummary)
                    
                    // Generations in session
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generations")
                            .font(.headline)
                        
                        ForEach(viewModel.selectedSessionGenerations, id: \.id) { generation in
                            GenerationRowView(generation: generation)
                        }
                    }
                    
                } else {
                    // No session selected
                    VStack(spacing: 16) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("Select a Session")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Choose a session from the Sessions tab to view detailed performance analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Model Comparison View

@available(iOS 14.0, macOS 11.0, *)
struct ModelComparisonView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Model comparison cards
                ForEach(viewModel.modelMetrics.keys.sorted(), id: \.self) { modelId in
                    if let metrics = viewModel.modelMetrics[modelId] {
                        ModelMetricsCard(modelId: modelId, metrics: metrics)
                    }
                }
                
                if viewModel.modelMetrics.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("No Model Data")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Model comparison data will appear here after running generations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

@available(iOS 14.0, macOS 11.0, *)
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct MetricChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct SessionDetailCard: View {
    let session: GenerationSession
    let summary: SessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Model ID", value: session.modelId)
                DetailRow(label: "Type", value: session.sessionType.rawValue.capitalized)
                DetailRow(label: "Started", value: session.startTime.formatted())
                
                if let endTime = session.endTime {
                    DetailRow(label: "Ended", value: endTime.formatted())
                }
                
                DetailRow(label: "Total Generations", value: "\(summary.totalGenerations)")
                DetailRow(label: "Total Duration", value: String(format: "%.1fs", summary.totalDuration))
                DetailRow(label: "Avg TTFT", value: String(format: "%.3fs", summary.averageTimeToFirstToken))
                DetailRow(label: "Avg Speed", value: String(format: "%.1f tok/s", summary.averageTokensPerSecond))
                DetailRow(label: "Total Tokens", value: "\(summary.totalInputTokens + summary.totalOutputTokens)")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct GenerationRowView: View {
    let generation: Generation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Generation #\(generation.sequenceNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(generation.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let performance = generation.performance {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1fs", performance.totalGenerationTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(String(format: "%.1f tok/s", performance.tokensPerSecond))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct ModelMetricsCard: View {
    let modelId: String
    let metrics: AverageMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(modelId)
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(metrics.sessionCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(metrics.generationCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f tok/s", metrics.averageTokensPerSecond))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}