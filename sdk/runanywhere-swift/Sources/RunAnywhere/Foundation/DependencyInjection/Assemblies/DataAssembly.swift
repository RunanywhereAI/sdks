import Foundation
import Swinject

/// Assembly for data layer services including repositories and database
final class DataAssembly: Assembly {
    func assemble(container: Container) {
        // Database Core - Placeholder for now since SQLiteDatabase needs async init
        // The actual database is created lazily by ServiceContainer
        container.register(DatabaseCore.self) { resolver in
            // This is a placeholder - the actual database is created async
            // by ServiceContainer when needed
            fatalError("Database must be initialized async - use ServiceContainer pattern")
        }
        .inObjectScope(.container)

        // Configuration Repository
        container.register(ConfigurationRepository.self) { resolver in
            ConfigurationRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)
            )
        }
        .inObjectScope(.container)

        // Model Metadata Repository
        container.register(ModelMetadataRepository.self) { resolver in
            ModelMetadataRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)
            )
        }
        .inObjectScope(.container)

        // Telemetry Repository
        container.register(TelemetryRepository.self) { resolver in
            TelemetryRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self)
            )
        }
        .inObjectScope(.container)

        // Data Sync Service
        container.register(DataSyncService.self) { resolver in
            DataSyncService(
                database: resolver.resolve(DatabaseCore.self)!,
                apiClient: resolver.resolve(APIClient.self),
                enableAutoSync: true
            )
        }
        .inObjectScope(.container)

        // Generation Analytics Repository - depends on DataSyncService
        container.register(GenerationAnalyticsRepository.self) { resolver in
            GenerationAnalyticsRepositoryImpl(
                database: resolver.resolve(DatabaseCore.self)!,
                syncService: resolver.resolve(DataSyncService.self)
            )
        }
        .inObjectScope(.container)
    }
}
