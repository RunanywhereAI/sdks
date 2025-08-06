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
            var config = LoggingConfiguration()
            config.minLogLevel = sdkConfig.debugMode ? .debug : .info
            config.enableLocalLogging = true
            config.enableRemoteLogging = false
            return config
        }

        // Remote Logger
        container.register(RemoteLogger.self) { _ in
            RemoteLogger()
        }

        // Logging Manager - Uses singleton
        container.register(LoggingManager.self) { _ in
            LoggingManager.shared
        }
        .inObjectScope(.container)

        // Environment Configuration - Uses current configuration
        container.register(EnvironmentConfiguration.self) { _ in
            EnvironmentConfiguration.current
        }
        .inObjectScope(.container)

        // SDK Logger
        container.register(SDKLogger.self) { _ in
            SDKLogger(category: "RunAnywhereSDK")
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
