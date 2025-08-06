import Foundation
import Moya

/// Moya plugin for collecting telemetry data
public final class TelemetryPlugin: PluginType {

    /// The telemetry service
    private let telemetryService: TelemetryService

    /// Initialize the telemetry plugin
    /// - Parameter telemetryService: The telemetry service instance
    public init(telemetryService: TelemetryService) {
        self.telemetryService = telemetryService
    }

    /// Track request initiation
    public func willSend(_ request: RequestType, target: TargetType) {
        let requestId = UUID().uuidString

        // Record request start
        telemetryService.recordRequestStart(
            requestId: requestId,
            endpoint: target.path,
            method: target.method.rawValue,
            timestamp: Date()
        )

        // Store request ID for later correlation
        request.sessionHeaders?["X-Telemetry-ID"] = requestId
    }

    /// Track response reception
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        let requestId = UUID().uuidString // Would be retrieved from request in production

        switch result {
        case .success(let response):
            // Record successful response
            telemetryService.recordRequestComplete(
                requestId: requestId,
                endpoint: target.path,
                statusCode: response.statusCode,
                responseTime: calculateResponseTime(),
                timestamp: Date()
            )

            // Track response size
            if let data = try? response.mapJSON() as? [String: Any] {
                let responseSize = response.data.count
                telemetryService.recordResponseSize(
                    endpoint: target.path,
                    size: responseSize
                )
            }

        case .failure(let error):
            // Record failed request
            telemetryService.recordRequestFailure(
                requestId: requestId,
                endpoint: target.path,
                error: error,
                timestamp: Date()
            )
        }
    }

    /// Process the request for telemetry
    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        // Track network metrics
        if case .success(let response) = result {
            // Extract performance metrics from headers
            if let serverTime = response.response?.value(forHTTPHeaderField: "X-Server-Processing-Time"),
               let processingTime = TimeInterval(serverTime) {
                telemetryService.recordServerProcessingTime(
                    endpoint: target.path,
                    time: processingTime
                )
            }

            // Track cache hits
            if let cacheStatus = response.response?.value(forHTTPHeaderField: "X-Cache-Status") {
                telemetryService.recordCacheStatus(
                    endpoint: target.path,
                    status: cacheStatus
                )
            }
        }

        return result
    }

    // MARK: - Private Methods

    private func calculateResponseTime() -> TimeInterval {
        // In production, this would calculate actual response time
        // For now, return a placeholder value
        return 0.0
    }
}

/// Service for managing telemetry data
public class TelemetryService {

    private let repository: TelemetryRepository?
    private let configuration: Configuration
    private let logger: SDKLogger

    /// Active request tracking
    private var activeRequests: [String: RequestMetrics] = [:]

    /// Thread safety queue
    private let queue = DispatchQueue(label: "com.runanywhere.telemetry", attributes: .concurrent)

    internal init(repository: TelemetryRepository?, configuration: Configuration, logger: SDKLogger) {
        self.repository = repository
        self.configuration = configuration
        self.logger = logger
    }

    /// Record request start
    public func recordRequestStart(requestId: String, endpoint: String, method: String, timestamp: Date) {
        guard configuration.telemetryConsent != .disabled else { return }

        queue.async(flags: .barrier) {
            self.activeRequests[requestId] = RequestMetrics(
                endpoint: endpoint,
                method: method,
                startTime: timestamp
            )
        }

        logger.debug("Request started: \(requestId) - \(method) \(endpoint)")
    }

    /// Record request completion
    public func recordRequestComplete(requestId: String, endpoint: String, statusCode: Int, responseTime: TimeInterval, timestamp: Date) {
        guard configuration.telemetryConsent != .disabled else { return }

        queue.async(flags: .barrier) {
            if var metrics = self.activeRequests[requestId] {
                metrics.endTime = timestamp
                metrics.statusCode = statusCode
                metrics.responseTime = responseTime

                // Send to repository
                Task {
                    await self.repository?.recordRequestMetrics(metrics)
                }

                // Clean up
                self.activeRequests.removeValue(forKey: requestId)
            }
        }

        logger.debug("Request completed: \(requestId) - Status: \(statusCode), Time: \(responseTime)s")
    }

    /// Record request failure
    public func recordRequestFailure(requestId: String, endpoint: String, error: MoyaError, timestamp: Date) {
        guard configuration.telemetryConsent != .disabled else { return }

        queue.async(flags: .barrier) {
            if var metrics = self.activeRequests[requestId] {
                metrics.endTime = timestamp
                metrics.error = error.localizedDescription

                // Send to repository
                Task {
                    await self.repository?.recordRequestMetrics(metrics)
                }

                // Clean up
                self.activeRequests.removeValue(forKey: requestId)
            }
        }

        logger.error("Request failed: \(requestId) - \(error.localizedDescription)")
    }

    /// Record response size
    public func recordResponseSize(endpoint: String, size: Int) {
        guard configuration.telemetryConsent == .full else { return }

        logger.debug("Response size for \(endpoint): \(size) bytes")

        Task {
            await repository?.recordMetric(
                name: "response_size",
                value: Double(size),
                tags: ["endpoint": endpoint]
            )
        }
    }

    /// Record server processing time
    public func recordServerProcessingTime(endpoint: String, time: TimeInterval) {
        guard configuration.telemetryConsent == .full else { return }

        logger.debug("Server processing time for \(endpoint): \(time)s")

        Task {
            await repository?.recordMetric(
                name: "server_processing_time",
                value: time,
                tags: ["endpoint": endpoint]
            )
        }
    }

    /// Record cache status
    public func recordCacheStatus(endpoint: String, status: String) {
        guard configuration.telemetryConsent == .full else { return }

        logger.debug("Cache status for \(endpoint): \(status)")

        Task {
            await repository?.recordMetric(
                name: "cache_status",
                value: status == "HIT" ? 1.0 : 0.0,
                tags: ["endpoint": endpoint, "status": status]
            )
        }
    }
}

/// Request metrics structure
public struct RequestMetrics {
    let endpoint: String
    let method: String
    let startTime: Date
    var endTime: Date?
    var statusCode: Int?
    var responseTime: TimeInterval?
    var error: String?
}

// MARK: - TelemetryRepository Extensions

extension TelemetryRepository {
    func recordRequestMetrics(_ metrics: RequestMetrics) async {
        // Implementation would go here
    }

    func recordMetric(name: String, value: Double, tags: [String: String]) async {
        // Implementation would go here
    }
}
