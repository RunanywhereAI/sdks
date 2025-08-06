import Foundation
import Moya

/// Moya plugin for handling API authentication
public struct AuthenticationPlugin: PluginType {

    /// Closure that provides the API key when needed
    let apiKeyProvider: () -> String?

    /// Initialize the authentication plugin
    /// - Parameter apiKeyProvider: Closure that returns the current API key
    public init(apiKeyProvider: @escaping () -> String?) {
        self.apiKeyProvider = apiKeyProvider
    }

    /// Prepare the request by adding authentication headers
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        // Add Bearer token if API key is available
        if let apiKey = apiKeyProvider() {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // Add additional security headers
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        request.setValue(String(Date().timeIntervalSince1970), forHTTPHeaderField: "X-Timestamp")

        return request
    }

    /// Handle authentication failures in responses
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            // Check for authentication errors
            if response.statusCode == 401 {
                NotificationCenter.default.post(
                    name: .apiAuthenticationFailed,
                    object: nil,
                    userInfo: ["target": target]
                )
            }
        case .failure:
            // Handle network failures if needed
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when API authentication fails
    static let apiAuthenticationFailed = Notification.Name("RunAnywhereAPIAuthenticationFailed")
}
