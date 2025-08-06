import Foundation
import Swinject

/// Core assembly for fundamental services like logging, environment configuration, and SDK configuration
final class CoreAssembly: Assembly {
    func assemble(container: Container) {
        // SDK Configuration - This will be injected from SDK initialization
        container.register(Configuration.self) { _ in
            fatalError("Configuration must be provided during SDK initialization")
        }

        // Logging Configuration
        container.register(LoggingConfiguration.self) { resolver in
            let sdkConfig = resolver.resolve(Configuration.self)!
            return LoggingConfiguration(
                level: sdkConfig.debugMode ? .debug : .info,
                enableConsoleLogging: true,
                enableFileLogging: false,
                enableRemoteLogging: false
            )
        }

        // Remote Logger
        container.register(RemoteLogger.self) { resolver in
            let config = resolver.resolve(Configuration.self)!
            return RemoteLogger(
                apiClient: resolver.resolve(APIClient.self),
                configuration: config,
                enabled: false
            )
        }

        // Logging Manager
        container.register(LoggingManager.self) { resolver in
            LoggingManager(
                configuration: resolver.resolve(LoggingConfiguration.self)!,
                remoteLogger: resolver.resolve(RemoteLogger.self)
            )
        }
        .inObjectScope(.container)

        // Environment Configuration
        container.register(EnvironmentConfiguration.self) { _ in
            EnvironmentConfiguration()
        }
        .inObjectScope(.container)

        // SDK Logger
        container.register(SDKLogger.self) { resolver in
            SDKLogger(
                loggingManager: resolver.resolve(LoggingManager.self)!,
                identifier: "RunAnywhereSDK"
            )
        }
        .inObjectScope(.container)

        // Configuration Validator
        container.register(ConfigurationValidator.self) { _ in
            ConfigurationValidator()
        }
        .inObjectScope(.container)

        // Format Detector - Using existing implementation
        container.register(FormatDetector.self) { _ in
            return FormatDetectorImpl()
        }
        .inObjectScope(.container)

        // Metadata Extractor
        container.register(MetadataExtractor.self) { _ in
            MetadataExtractorImpl()
        }
        .inObjectScope(.container)

        // Simplified File Manager
        container.register(SimplifiedFileManager.self) { _ in
            do {
                return try SimplifiedFileManager()
            } catch {
                fatalError("Failed to initialize file manager: \(error)")
            }
        }
        .inObjectScope(.container)
    }
}
