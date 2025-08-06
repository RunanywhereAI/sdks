import Foundation
import Swinject

/// Service container for dependency injection - migrated to use Swinject
/// This class now acts as a facade over the Swinject-based SDKAssembler
public class ServiceContainer {
    /// Shared instance
    public static let shared: ServiceContainer = ServiceContainer()

    /// The SDK assembler that manages all dependencies
    private var assembler: SDKAssembler?

    /// The Swinject resolver for accessing services
    private var resolver: Resolver? {
        return assembler?.synchronizedResolver
    }
    // MARK: - Core Services

    /// Configuration validator
    public var configurationValidator: ConfigurationValidator {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ConfigurationValidator.self)
    }

    /// Model registry
    public var modelRegistry: ModelRegistry {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(RegistryService.self)
    }

    /// Framework adapter registry
    internal var adapterRegistry: FrameworkAdapterRegistry {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(FrameworkAdapterRegistry.self)
    }


    // MARK: - Capability Services

    /// Model loading service
    public var modelLoadingService: ModelLoadingService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ModelLoadingService.self)
    }

    /// Generation service
    public var generationService: GenerationService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(GenerationService.self)
    }

    /// Streaming service
    public var streamingService: StreamingService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(StreamingService.self)
    }

    /// Context manager
    public var contextManager: ContextManager {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ContextManager.self)
    }

    /// Validation service
    public var validationService: ValidationService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ValidationService.self)
    }

    /// Download service
    public var downloadService: AlamofireDownloadService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(AlamofireDownloadService.self)
    }

    // Download queue removed - handled by AlamofireDownloadService

    /// Progress service (implements ProgressTracker protocol)
    public var progressService: ProgressTracker {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ProgressService.self)
    }

    // Storage service removed - replaced by SimplifiedFileManager
    // Model storage manager removed - replaced by SimplifiedFileManager

    /// Simplified file manager
    public var fileManager: SimplifiedFileManager {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(SimplifiedFileManager.self)
    }

    /// Routing service
    public var routingService: RoutingService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(RoutingService.self)
    }

    // Memory service and monitor placeholders removed - using unifiedMemoryManager instead

    // MARK: - Monitoring Services

    /// Performance monitor
    public var performanceMonitor: PerformanceMonitor {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(MonitoringService.self)
    }

    // Storage monitor removed - storage monitoring handled by SimplifiedFileManager

    /// Benchmark runner
    public var benchmarkRunner: BenchmarkRunner {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(BenchmarkService.self)
    }

    /// A/B test runner
    public var abTestRunner: ABTestRunner {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ABTestService.self)
    }

    // MARK: - Infrastructure

    /// Hardware manager
    public var hardwareManager: HardwareCapabilityManager {
        return HardwareCapabilityManager.shared
    }

    /// Memory service (implements MemoryManager protocol)
    public var memoryService: MemoryManager {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(MemoryService.self)
    }

    /// Error recovery service
    public var errorRecoveryService: ErrorRecoveryService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(ErrorRecoveryService.self)
    }

    /// Compatibility service
    public var compatibilityService: CompatibilityService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(CompatibilityService.self)
    }

    /// Tokenization service
    public var tokenizerService: TokenizerService {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(TokenizerService.self)
    }

    /// Format detector for model validation
    public var formatDetector: FormatDetector {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(FormatDetector.self)
    }

    /// Metadata extractor for model validation
    public var metadataExtractor: MetadataExtractor {
        guard let resolver = resolver else {
            fatalError("ServiceContainer not initialized. Call bootstrap() first.")
        }
        return resolver.resolveRequired(MetadataExtractor.self)
    }

    /// Logger
    public var logger: SDKLogger {
        guard let resolver = resolver else {
            // Allow logger to be created before bootstrap for early logging
            return SDKLogger()
        }
        return resolver.resolveRequired(SDKLogger.self)
    }

    /// Configuration service (either ConfigurationService or InMemoryConfigurationService)
    private var _configurationService: ConfigurationServiceProtocol?
    public var configurationService: ConfigurationServiceProtocol {
        guard let service = _configurationService else {
            fatalError("ConfigurationService must be initialized via bootstrap")
        }
        return service
    }

    /// Database service
    private var _database: DatabaseCore?

    /// Get database (lazy initialization) - TEMPORARILY DISABLED DUE TO CORRUPTED JSON
    private var database: DatabaseCore? {
        get async {
            // COMMENTED OUT: Database temporarily disabled to avoid JSON corruption issues
            // if _database == nil {
            //     do {
            //         _database = try await SQLiteDatabase()
            //     } catch {
            //         logger.error("Failed to initialize Database: \(error)")
            //     }
            // }
            // return _database

            // Return nil to force in-memory configuration
            logger.warning("Database disabled - using in-memory configuration only")
            return nil
        }
    }

    /// API client for sync operations
    private var apiClient: APIClient?

    /// Data sync service
    private var _dataSyncService: DataSyncService?

    public var dataSyncService: DataSyncService? {
        get async {
            if _dataSyncService == nil {
                if let db = await database {
                    _dataSyncService = DataSyncService(
                        database: db,
                        apiClient: apiClient,
                        enableAutoSync: true
                    )
                }
            }
            return _dataSyncService
        }
    }

    /// Generation analytics service
    private var _generationAnalytics: GenerationAnalyticsService?

    public var generationAnalytics: GenerationAnalyticsService {
        get async {
            if _generationAnalytics == nil {
                if let db = await database,
                   let syncService = await dataSyncService {
                    let repository = GenerationAnalyticsRepositoryImpl(
                        database: db,
                        syncService: syncService
                    )

                    // Get telemetry repository from data sync service
                    let telemetryRepo = syncService.telemetryRepository

                    _generationAnalytics = GenerationAnalyticsServiceImpl(
                        repository: repository,
                        telemetryService: telemetryRepo,
                        performanceMonitor: performanceMonitor
                    )
                } else {
                    // Database is disabled, create no-op analytics service
                    logger.warning("Creating no-op GenerationAnalytics service (database disabled)")
                    _generationAnalytics = NoOpGenerationAnalyticsService()
                }
            }

            guard let analytics = _generationAnalytics else {
                logger.error("GenerationAnalytics service not available")
                fatalError("Failed to initialize GenerationAnalytics service")
            }

            return analytics
        }
    }


    // MARK: - Public Service Access

    /// Get error recovery service
    public var errorRecovery: ErrorRecoveryService {
        return errorRecoveryService
    }

    /// Get compatibility service
    public var compatibility: CompatibilityService {
        return compatibilityService
    }

    /// Get tokenizer service
    public var tokenizer: TokenizerService {
        return tokenizerService
    }

    /// Get memory service
    public var memory: MemoryManager {
        return memoryService
    }

    /// Get progress service
    public var progress: ProgressTracker {
        return progressService
    }

    // MARK: - Initialization

    public init() {
        // Container is ready for lazy initialization
    }

    /// Bootstrap all services with configuration
    public func bootstrap(with configuration: Configuration) async throws {
        // Initialize the SDKAssembler with the configuration
        self.assembler = SDKAssembler(configuration: configuration)

        // The assembler now handles all service initialization through Swinject
        // All services are configured through their respective assemblies

        // Start service health monitoring if enabled
        if configuration.enableRealTimeDashboard {
            await startHealthMonitoring()
        }

        logger.info("ServiceContainer bootstrapped with Swinject assembler")
    }

    /// Check health of all services
    public func checkServiceHealth() async -> [String: Bool] {
        var health: [String: Bool] = [:]

        health["memory"] = await checkMemoryServiceHealth()
        health["download"] = await checkDownloadServiceHealth()
        health["storage"] = await checkStorageServiceHealth()
        health["validation"] = await checkValidationServiceHealth()
        health["compatibility"] = await checkCompatibilityServiceHealth()
        health["tokenizer"] = await checkTokenizerServiceHealth()

        return health
    }

    private func startHealthMonitoring() async {
        // Start periodic health checks every 30 seconds
        Task {
            while !Task.isCancelled {
                let health = await checkServiceHealth()
                let unhealthyServices = health.filter { !$0.value }.map { $0.key }

                if !unhealthyServices.isEmpty {
                    logger.warning("Unhealthy services detected: \(unhealthyServices.joined(separator: ", "))")
                }

                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }

    private func checkMemoryServiceHealth() async -> Bool {
        // Basic health check - ensure memory service is responsive
        return memoryService.isHealthy()
    }

    private func checkDownloadServiceHealth() async -> Bool {
        // Check if download service can handle requests
        return downloadService.isHealthy()
    }

    private func checkStorageServiceHealth() async -> Bool {
        // Check storage service health
        return true // SimplifiedFileManager doesn't need health checks
    }

    private func checkValidationServiceHealth() async -> Bool {
        // Check validation service
        return validationService.isHealthy()
    }

    private func checkCompatibilityServiceHealth() async -> Bool {
        // Check compatibility service
        return compatibilityService.isHealthy()
    }

    private func checkTokenizerServiceHealth() async -> Bool {
        // Check tokenizer service
        return tokenizerService.isHealthy()
    }
}
