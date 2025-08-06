import Foundation
import Swinject

/// Main assembler for the SDK that coordinates all dependency injection assemblies
public final class SDKAssembler {
    private let assembler: Assembler
    private let container: Container

    /// Initialize the SDK assembler with a configuration
    /// - Parameter configuration: The SDK configuration to use
    public init(configuration: Configuration) {
        // Create container
        self.container = Container()

        // Register the configuration itself as a dependency
        container.register(Configuration.self) { _ in configuration }
            .inObjectScope(.container)

        // Initialize assembler with all assemblies in the correct order
        // Order matters: Core -> Data/Network -> Capabilities -> Model Loading -> Public
        self.assembler = Assembler(
            [
                CoreAssembly(),        // Core services (Logger, Environment)
                NetworkAssembly(),     // Network services (Moya, API clients)
                DataAssembly(),        // Data layer (Repositories, Database)
                CapabilityAssembly(),  // Capability services
                ModelLoadingAssembly(), // Model loading and validation
                PublicAssembly()       // Public API services
            ],
            container: container
        )

        // Perform post-assembly setup if needed
        performPostAssemblySetup()
    }

    /// The resolver for accessing registered services
    public var resolver: Resolver {
        assembler.resolver
    }

    /// Thread-safe resolver for concurrent access
    public var synchronizedResolver: Resolver {
        assembler.resolver.synchronize()
    }

    /// Get the main SDK instance
    public func getSDK() -> RunAnywhereSDK? {
        return resolver.resolve(RunAnywhereSDK.self)
    }

    // MARK: - Private Methods

    private func performPostAssemblySetup() {
        // Any post-assembly setup can be done here
        // For example, initializing services that require special setup
    }
}

// MARK: - Container Extensions

extension Container {
    /// Synchronize the container for thread-safe access
    public func synchronize() -> Resolver {
        return self.synchronize()
    }
}

// MARK: - Resolver Extensions

extension Resolver {
    /// Resolve a service with a more convenient syntax
    /// - Returns: The resolved service or nil if not found
    public func resolveOptional<Service>(_ serviceType: Service.Type) -> Service? {
        return self.resolve(serviceType)
    }

    /// Resolve a service with a fatal error if not found
    /// - Returns: The resolved service
    public func resolveRequired<Service>(_ serviceType: Service.Type) -> Service {
        guard let service = self.resolve(serviceType) else {
            fatalError("Failed to resolve required service: \(serviceType)")
        }
        return service
    }
}
