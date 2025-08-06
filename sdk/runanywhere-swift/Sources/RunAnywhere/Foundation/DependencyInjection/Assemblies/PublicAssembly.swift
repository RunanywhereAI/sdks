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
            BenchmarkService(
                executor: BenchmarkExecutor(
                    generationService: resolver.resolve(GenerationService.self)!,
                    logger: resolver.resolve(SDKLogger.self)!
                ),
                metricsAggregator: BenchmarkMetricsAggregator(),
                reportGenerator: BenchmarkReportGenerator(),
                comparisonEngine: ComparisonEngine(),
                promptManager: PromptManager(),
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // A/B Testing Service
        container.register(ABTestService.self) { resolver in
            ABTestService(
                lifecycleManager: TestLifecycleManager(),
                variantManager: VariantManager(),
                metricsCollector: TestMetricsCollector(),
                resultAnalyzer: ResultAnalyzer(),
                generationTracker: ABTestGenerationTracker(),
                logger: resolver.resolve(SDKLogger.self)!
            )
        }
        .inObjectScope(.container)

        // Note: RunAnywhereSDK is a singleton and should not be created by DI
        // It uses ServiceContainer internally which has been migrated to use Swinject
    }
}
