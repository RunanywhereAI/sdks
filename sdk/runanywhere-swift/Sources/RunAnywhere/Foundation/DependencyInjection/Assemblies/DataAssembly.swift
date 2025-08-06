import Foundation
import Swinject

/// Assembly for data layer services including repositories and database
final class DataAssembly: Assembly {
    func assemble(container: Container) {
        // Database Core
        container.register(DatabaseCore.self) { resolver in
            let configuration = resolver.resolve(Configuration.self)!
            let logger = resolver.resolve(SDKLogger.self)!

            return SQLiteDatabase(
                configuration: configuration.storage,
                logger: logger
            )
        }
        .inObjectScope(.container)

        // Configuration Repository
        container.register(ConfigurationRepository.self) { resolver in
            ConfigurationRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Model Metadata Repository
        container.register(ModelMetadataRepository.self) { resolver in
            ModelMetadataRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Telemetry Repository
        container.register(TelemetryRepository.self) { resolver in
            TelemetryRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Generation Analytics Repository
        container.register(GenerationAnalyticsRepository.self) { resolver in
            GenerationAnalyticsRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Data Sync Service
        container.register(DataSyncService.self) { resolver in
            DataSyncService(
                configurationRepository: resolver.resolve(ConfigurationRepository.self)!,
                modelMetadataRepository: resolver.resolve(ModelMetadataRepository.self)!,
                telemetryRepository: resolver.resolve(TelemetryRepository.self)!,
                apiClient: resolver.resolve(APIClient.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)
    }
}
