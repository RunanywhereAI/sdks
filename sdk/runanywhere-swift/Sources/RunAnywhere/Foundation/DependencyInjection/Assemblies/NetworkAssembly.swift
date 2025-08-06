import Foundation
import Swinject
import Moya
import Alamofire

/// Assembly for network layer services including Moya providers and API clients
final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        // Authentication Plugin
        container.register(AuthenticationPlugin.self) { resolver in
            let configuration = resolver.resolve(Configuration.self)!
            return AuthenticationPlugin(apiKeyProvider: { configuration.apiKey })
        }

        // Cost Tracking Plugin
        container.register(CostTrackingPlugin.self) { resolver in
            let costTracker = resolver.resolve(CostTrackingService.self)!
            return CostTrackingPlugin(costTracker: costTracker)
        }

        // Telemetry Plugin
        container.register(TelemetryPlugin.self) { resolver in
            let telemetryService = resolver.resolve(TelemetryService.self)!
            return TelemetryPlugin(telemetryService: telemetryService)
        }

        // Moya Provider for RunAnywhereAPI
        container.register(MoyaProvider<RunAnywhereAPI>.self) { resolver in
            let configuration = resolver.resolve(Configuration.self)!
            let authPlugin = resolver.resolve(AuthenticationPlugin.self)!
            let costPlugin = resolver.resolve(CostTrackingPlugin.self)!
            let telemetryPlugin = resolver.resolve(TelemetryPlugin.self)!

            let plugins: [PluginType] = [
                authPlugin,
                costPlugin,
                telemetryPlugin,
                NetworkLoggerPlugin(configuration: .init(
                    formatter: .init(responseData: JSONResponseDataFormatter),
                    logOptions: configuration.debugMode ? .verbose : .default
                ))
            ]

            // Custom endpoint closure to add SDK headers
            let endpointClosure = { (target: RunAnywhereAPI) -> Endpoint in
                MoyaProvider.defaultEndpointMapping(for: target)
                    .adding(newHTTPHeaderFields: [
                        "X-SDK-Version": SDKConstants.version,
                        "X-Platform": "iOS",
                        "X-SDK-Language": "Swift"
                    ])
            }

            // Custom session configuration
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 30
            sessionConfig.timeoutIntervalForResource = 300

            let session = Session(configuration: sessionConfig)

            return MoyaProvider<RunAnywhereAPI>(
                endpointClosure: endpointClosure,
                session: session,
                plugins: plugins,
                trackInflights: true
            )
        }
        .inObjectScope(.container)

        // Moya API Client
        container.register(MoyaAPIClient.self) { resolver in
            let provider = resolver.resolve(MoyaProvider<RunAnywhereAPI>.self)!
            let logger = resolver.resolve(SDKLogger.self)!

            return MoyaAPIClient(
                provider: provider,
                decoder: JSONDecoder(),
                encoder: JSONEncoder(),
                logger: logger
            )
        }
        .inObjectScope(.container)

        // Legacy API Client (will be replaced by Moya eventually)
        container.register(APIClient.self) { resolver in
            let config = resolver.resolve(Configuration.self)!
            return APIClient(
                baseURL: config.baseURL.absoluteString,
                apiKey: config.apiKey
            )
        }
        .inObjectScope(.container)

        // Legacy Alamofire Download Service (will be migrated later)
        container.register(AlamofireDownloadService.self) { _ in
            return AlamofireDownloadService()
        }
        .inObjectScope(.container)
    }
}

/// JSON Response Data Formatter for NetworkLoggerPlugin
private func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}
