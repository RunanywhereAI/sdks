import Foundation
import Swinject

/// Assembly for capability services including hardware detection, routing, and device capabilities
final class CapabilityAssembly: Assembly {
    func assemble(container: Container) {
        // Hardware Detection Services
        container.register(ProcessorDetector.self) { _ in
            ProcessorDetector()
        }
        .inObjectScope(.container)

        container.register(GPUDetector.self) { _ in
            GPUDetector()
        }
        .inObjectScope(.container)

        container.register(NeuralEngineDetector.self) { _ in
            NeuralEngineDetector()
        }
        .inObjectScope(.container)

        // Battery and Thermal Monitoring
        container.register(BatteryMonitorService.self) { resolver in
            BatteryMonitorService(
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        container.register(ThermalMonitorService.self) { resolver in
            ThermalMonitorService(
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Capability Analyzer
        container.register(CapabilityAnalyzer.self) { resolver in
            CapabilityAnalyzer(
                processorDetector: resolver.resolve(ProcessorDetector.self),
                neuralEngineDetector: resolver.resolve(NeuralEngineDetector.self),
                gpuDetector: resolver.resolve(GPUDetector.self)
            )
        }
        .inObjectScope(.container)

        // Compatibility Services
        container.register(CompatibilityService.self) { _ in
            CompatibilityService()
        }
        .inObjectScope(.container)

        container.register(FrameworkRecommender.self) { resolver in
            FrameworkRecommender(
                compatibilityService: resolver.resolve(CompatibilityService.self)!
            )
        }
        .inObjectScope(.container)

        // Cost Calculator
        container.register(CostCalculator.self) { _ in
            CostCalculator()
        }
        .inObjectScope(.container)

        // Resource Checker
        container.register(ResourceChecker.self) { resolver in
            ResourceChecker(hardwareManager: HardwareCapabilityManager.shared)
        }
        .inObjectScope(.container)

        // Cost Estimation Service - placeholder for now
        // Note: CostEstimationService is not yet defined
        // Will be implemented when needed

        // Cost Tracking Service
        container.register(CostTrackingService.self) { resolver in
            CostTrackingService(
                repository: resolver.resolve(TelemetryRepository.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Routing Service
        container.register(RoutingService.self) { resolver in
            return RoutingService(
                costCalculator: resolver.resolve(CostCalculator.self)!,
                resourceChecker: resolver.resolve(ResourceChecker.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Configuration Service
        container.register(ConfigurationServiceProtocol.self) { resolver in
            ConfigurationService(
                configRepository: resolver.resolve(ConfigurationRepository.self)!
            )
        }
        .inObjectScope(.container)

        // Telemetry Service
        container.register(TelemetryService.self) { resolver in
            TelemetryService(
                repository: resolver.resolve(TelemetryRepository.self)!,
                configuration: resolver.resolve(Configuration.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Memory Services
        container.register(MemoryMonitor.self) { resolver in
            MemoryMonitor(
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        container.register(MemoryService.self) { resolver in
            MemoryService(
                memoryMonitor: resolver.resolve(MemoryMonitor.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Lifecycle Service
        container.register(LifecycleService.self) { resolver in
            LifecycleService(
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Progress Service
        container.register(ProgressService.self) { resolver in
            ProgressService(
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Monitoring Service
        container.register(MonitoringService.self) { _ in
            MonitoringService.shared
        }
        .inObjectScope(.container)

        // Profiling Service
        container.register(ProfilerService.self) { _ in
            ProfilerService.shared
        }
        .inObjectScope(.container)

        // Error Recovery Service
        container.register(ErrorRecoveryService.self) { _ in
            ErrorRecoveryService()
        }
        .inObjectScope(.container)
    }
}
