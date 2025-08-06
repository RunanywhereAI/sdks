import Foundation
import Moya

/// Moya plugin for tracking API usage costs
public final class CostTrackingPlugin: PluginType {

    /// The cost tracking service
    private let costTracker: CostTrackingService

    /// Initialize the cost tracking plugin
    /// - Parameter costTracker: The cost tracking service instance
    public init(costTracker: CostTrackingService) {
        self.costTracker = costTracker
    }

    /// Process the response to extract and track cost information
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard case .success(let response) = result else { return }

        // Extract cost information from response headers
        if let costHeader = response.response?.value(forHTTPHeaderField: "X-API-Cost"),
           let cost = Double(costHeader) {

            // Track the API usage cost
            costTracker.recordAPIUsage(
                endpoint: target.path,
                cost: cost,
                timestamp: Date()
            )
        }

        // Extract token usage if available
        if let tokensHeader = response.response?.value(forHTTPHeaderField: "X-Tokens-Used"),
           let tokens = Int(tokensHeader) {

            costTracker.recordTokenUsage(
                endpoint: target.path,
                tokens: tokens,
                timestamp: Date()
            )
        }

        // Extract execution target information
        if let executionTarget = response.response?.value(forHTTPHeaderField: "X-Execution-Target") {
            costTracker.recordExecutionTarget(
                endpoint: target.path,
                target: executionTarget,
                timestamp: Date()
            )
        }

        // Track rate limit information
        if let rateLimitRemaining = response.response?.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remaining = Int(rateLimitRemaining) {

            let rateLimitTotal = response.response?.value(forHTTPHeaderField: "X-RateLimit-Limit").flatMap { Int($0) }
            let rateLimitReset = response.response?.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { TimeInterval($0) }

            costTracker.updateRateLimitInfo(
                remaining: remaining,
                total: rateLimitTotal,
                resetTime: rateLimitReset.map { Date(timeIntervalSince1970: $0) }
            )
        }
    }
}

/// Service for tracking API costs and usage
public class CostTrackingService {

    private let repository: TelemetryRepository?
    private let logger: SDKLogger

    /// Current cost accumulator
    private var currentSessionCost: Double = 0.0

    /// Current token usage
    private var currentSessionTokens: Int = 0

    /// Rate limit information
    private var rateLimitInfo: RateLimitInfo?

    /// Thread safety queue
    private let queue = DispatchQueue(label: "com.runanywhere.costtracking", attributes: .concurrent)

    internal init(repository: TelemetryRepository?, logger: SDKLogger) {
        self.repository = repository
        self.logger = logger
    }

    /// Record API usage cost
    public func recordAPIUsage(endpoint: String, cost: Double, timestamp: Date) {
        queue.async(flags: .barrier) {
            self.currentSessionCost += cost
            self.logger.debug("API cost recorded: \(cost) for endpoint: \(endpoint)")

            // Store in repository if available
            Task {
                await self.repository?.recordCostMetric(
                    endpoint: endpoint,
                    cost: cost,
                    timestamp: timestamp
                )
            }
        }
    }

    /// Record token usage
    public func recordTokenUsage(endpoint: String, tokens: Int, timestamp: Date) {
        queue.async(flags: .barrier) {
            self.currentSessionTokens += tokens
            self.logger.debug("Token usage recorded: \(tokens) for endpoint: \(endpoint)")

            // Store in repository if available
            Task {
                await self.repository?.recordTokenMetric(
                    endpoint: endpoint,
                    tokens: tokens,
                    timestamp: timestamp
                )
            }
        }
    }

    /// Record execution target
    public func recordExecutionTarget(endpoint: String, target: String, timestamp: Date) {
        logger.debug("Execution target recorded: \(target) for endpoint: \(endpoint)")

        // Store in repository if available
        Task {
            await repository?.recordExecutionTarget(
                endpoint: endpoint,
                target: target,
                timestamp: timestamp
            )
        }
    }

    /// Update rate limit information
    public func updateRateLimitInfo(remaining: Int, total: Int?, resetTime: Date?) {
        queue.async(flags: .barrier) {
            self.rateLimitInfo = RateLimitInfo(
                remaining: remaining,
                total: total,
                resetTime: resetTime
            )

            if remaining < 10 {
                self.logger.warning("Low API rate limit: \(remaining) requests remaining")
            }
        }
    }

    /// Get current session cost
    public func getCurrentSessionCost() -> Double {
        queue.sync {
            return currentSessionCost
        }
    }

    /// Get current session token usage
    public func getCurrentSessionTokens() -> Int {
        queue.sync {
            return currentSessionTokens
        }
    }

    /// Get rate limit information
    public func getRateLimitInfo() -> RateLimitInfo? {
        queue.sync {
            return rateLimitInfo
        }
    }

    /// Reset session metrics
    public func resetSessionMetrics() {
        queue.async(flags: .barrier) {
            self.currentSessionCost = 0.0
            self.currentSessionTokens = 0
            self.logger.info("Session metrics reset")
        }
    }
}

/// Rate limit information
public struct RateLimitInfo {
    public let remaining: Int
    public let total: Int?
    public let resetTime: Date?
}

// MARK: - TelemetryRepository Extensions

extension TelemetryRepository {
    func recordCostMetric(endpoint: String, cost: Double, timestamp: Date) async {
        // Implementation would go here
    }

    func recordTokenMetric(endpoint: String, tokens: Int, timestamp: Date) async {
        // Implementation would go here
    }

    func recordExecutionTarget(endpoint: String, target: String, timestamp: Date) async {
        // Implementation would go here
    }
}
