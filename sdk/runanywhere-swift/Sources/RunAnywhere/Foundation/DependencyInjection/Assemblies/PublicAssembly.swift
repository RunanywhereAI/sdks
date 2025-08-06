import Foundation
import Swinject

/// Assembly for public API services including text generation and the main SDK
final class PublicAssembly: Assembly {
    func assemble(container: Container) {
        // Context Manager
        container.register(ContextManager.self) { resolver in
            ContextManager()
        }
        .inObjectScope(.container)

        // Thinking Parser
        container.register(ThinkingParser.self) { resolver in
            ThinkingParser()
        }

        // Generation Service
        container.register(GenerationService.self) { resolver in
            GenerationService(
                routingService: resolver.resolve(RoutingService.self)!,
                contextManager: resolver.resolve(ContextManager.self)!,
                performanceMonitor: resolver.resolve(MonitoringService.self)!,
                modelLoadingService: resolver.resolve(ModelLoadingService.self)!,
                structuredOutputHandler: resolver.resolve(StructuredOutputHandler.self)!
            )
        }
        .inObjectScope(.container)

        // Streaming Service
        container.register(StreamingService.self) { resolver in
            StreamingService(
                generationService: resolver.resolve(GenerationService.self)!,
                modelLoadingService: resolver.resolve(ModelLoadingService.self)!
            )
        }
        .inObjectScope(.container)

        // Structured Output Handler
        container.register(StructuredOutputHandler.self) { resolver in
            StructuredOutputHandler()
        }
        .inObjectScope(.container)

        // Generation Analytics Service
        container.register(GenerationAnalyticsService.self) { resolver in
            let configuration = resolver.resolve(Configuration.self)!

            // For now, always return NoOp since analytics is optional
            return NoOpGenerationAnalyticsService()
        }
        .inObjectScope(.container)

        // Benchmarking Service
        container.register(BenchmarkService.self) { resolver in
            // Note: BenchmarkService initialization needs to be fixed
            // once its dependencies are properly defined
            fatalError("BenchmarkService initialization not yet implemented")
        }
        .inObjectScope(.container)

        // A/B Testing Service
        container.register(ABTestService.self) { resolver in
            // Note: ABTestService initialization needs to be fixed
            // once its dependencies are properly defined
            fatalError("ABTestService initialization not yet implemented")
        }
        .inObjectScope(.container)

        // Note: RunAnywhereSDK is a singleton and should not be created by DI
        // It uses ServiceContainer internally which has been migrated to use Swinject
    }
}
