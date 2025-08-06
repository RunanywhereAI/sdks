import Foundation

/// Factory for creating services with proper dependencies
public class ServiceFactory {
    private let container: ServiceContainer

    /// Initialize with service container
    public init(container: ServiceContainer) {
        self.container = container
    }

    /// Create a new instance of a service
    public func create<T>(_ type: T.Type) -> T? {
        switch type {
        case is ModelLoadingService.Type:
            return createModelLoadingService() as? T

        case is GenerationService.Type:
            return createGenerationService() as? T

        case is ValidationService.Type:
            return createValidationService() as? T

        case is RegistryService.Type:
            return createRegistryService() as? T

        case is ContextManager.Type:
            return createContextManager() as? T

        default:
            return nil
        }
    }

    // MARK: - Private Factory Methods

    private func createModelLoadingService() -> ModelLoadingService {
        ModelLoadingService(
            registry: container.modelRegistry,
            adapterRegistry: container.adapterRegistry,
            validationService: container.validationService,
            memoryService: container.memoryService,
            logger: SDKLogger(category: "ModelLoadingService")
        )
    }

    private func createGenerationService() -> GenerationService {
        GenerationService(
            routingService: container.routingService,
            contextManager: container.contextManager,
            performanceMonitor: container.performanceMonitor
        )
    }

    private func createValidationService() -> ValidationService {
        ValidationService()
    }

    private func createRegistryService() -> RegistryService {
        RegistryService()
    }

    private func createContextManager() -> ContextManager {
        ContextManager()
    }

    /// Create a service with custom configuration
    public func createWithConfig<T>(_ type: T.Type, config: Any) -> T? {
        // This can be extended to support custom configurations
        // For now, delegate to standard create
        return create(type)
    }

    /// Register a custom factory method
    public func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        // This would store custom factories in a dictionary
        // For extensibility in the future
    }
}
