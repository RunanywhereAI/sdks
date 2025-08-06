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

        container.register(HardwareDetectionService.self) { resolver in
            HardwareDetectionService(
                processorDetector: resolver.resolve(ProcessorDetector.self)!,
                gpuDetector: resolver.resolve(GPUDetector.self)!,
                neuralEngineDetector: resolver.resolve(NeuralEngineDetector.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Battery and Thermal Monitoring
        container.register(BatteryMonitorService.self) { resolver in
            BatteryMonitorService(logger: resolver.resolve(SDKLogger.self)!)
        }
        .inObjectScope(.container)

        container.register(ThermalMonitorService.self) { resolver in
            ThermalMonitorService(logger: resolver.resolve(SDKLogger.self)!)
        }
        .inObjectScope(.container)

        // Capability Analyzer
        container.register(CapabilityAnalyzer.self) { resolver in
            CapabilityAnalyzer(
                hardwareService: resolver.resolve(HardwareDetectionService.self)!,
                batteryService: resolver.resolve(BatteryMonitorService.self)!,
                thermalService: resolver.resolve(ThermalMonitorService.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Compatibility Services
        container.register(CompatibilityService.self) { resolver in
            CompatibilityService(
                hardwareService: resolver.resolve(HardwareDetectionService.self)!,
                frameworkRegistry: resolver.resolve(FrameworkAdapterRegistry.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        container.register(FrameworkRecommender.self) { resolver in
            FrameworkRecommender(
                compatibilityService: resolver.resolve(CompatibilityService.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Cost Estimation Service
        container.register(CostEstimationService.self) { resolver in
            CostEstimationService(
                configuration: resolver.resolve(Configuration.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

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
            let configuration = resolver.resolve(Configuration.self)!
            return RoutingService(
                configuration: configuration.routing,
                hardwareService: resolver.resolve(HardwareDetectionService.self)!,
                costEstimator: resolver.resolve(CostEstimationService.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Configuration Service
        container.register(ConfigurationServiceProtocol.self) { resolver in
            ConfigurationService(
                repository: resolver.resolve(ConfigurationRepository.self)!,
                validator: resolver.resolve(ConfigurationValidator.self)!,
                logger: resolver.resolve(SDKLogger.self)!
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
            MemoryMonitor(logger: resolver.resolve(SDKLogger.self)!)
        }
        .inObjectScope(.container)

        container.register(MemoryService.self) { resolver in
            MemoryService(
                monitor: resolver.resolve(MemoryMonitor.self)!,
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Lifecycle Service
        container.register(LifecycleService.self) { resolver in
            LifecycleService(logger: resolver.resolve(SDKLogger.self)!)
        }
        .inObjectScope(.container)

        // Progress Service
        container.register(ProgressService.self) { resolver in
            ProgressService(logger: resolver.resolve(SDKLogger.self)!)
        }
        .inObjectScope(.container)

        // Monitoring Service
        container.register(MonitoringService.self) { resolver in
            MonitoringService(
                systemMetricsCollector: SystemMetricsCollector(),
                alertManager: AlertManager(),
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Profiling Service
        container.register(ProfilerService.self) { resolver in
            ProfilerService(
                memoryAnalyzer: MemoryAnalyzer(),
                allocationTracker: AllocationTracker(),
                leakDetector: LeakDetector(),
                recommendationEngine: RecommendationEngine(),
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Error Recovery Service
        container.register(ErrorRecoveryService.self) { resolver in
            ErrorRecoveryService(
                strategySelector: StrategySelector(),
                recoveryExecutor: RecoveryExecutor(),
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)
    }
}
