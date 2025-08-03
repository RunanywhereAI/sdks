package com.runanywhere.sdk.example

import com.runanywhere.sdk.RunAnywhereSDK
import com.runanywhere.sdk.configuration.*
import com.runanywhere.sdk.models.*
import com.runanywhere.sdk.errors.RunAnywhereError
import kotlinx.coroutines.runBlocking

/**
 * Example usage of the RunAnywhere Android SDK
 */
class SDKExample {
    
    fun runExample() = runBlocking {
        try {
            // 1. Initialize the SDK
            println("Initializing SDK...")
            val configuration = Configuration(
                apiKey = "your-api-key-here",
                enableRealTimeDashboard = true,
                telemetryConsent = TelemetryConsent.GRANTED,
                routingPolicy = RoutingPolicy.AUTOMATIC,
                privacyMode = PrivacyMode.STANDARD,
                preferredFrameworks = listOf(
                    LLMFramework.TENSORFLOW_LITE,
                    LLMFramework.ONNX
                ),
                hardwarePreferences = HardwareConfiguration(
                    primaryAccelerator = HardwareAcceleration.GPU,
                    fallbackAccelerator = HardwareAcceleration.CPU,
                    memoryMode = HardwareConfiguration.MemoryMode.BALANCED,
                    threadCount = 4
                )
            )
            
            RunAnywhereSDK.shared.initialize(configuration)
            println("SDK initialized successfully!")
            
            // 2. Check available frameworks
            println("\nChecking available frameworks...")
            val availableFrameworks = RunAnywhereSDK.shared.getAvailableFrameworks()
            println("Available frameworks: ${availableFrameworks.joinToString(", ") { it.displayName }}")
            
            val frameworkAvailability = RunAnywhereSDK.shared.getFrameworkAvailability()
            frameworkAvailability.forEach { info ->
                println("${info.framework.displayName}: ${if (info.isAvailable) "✅ Available" else "❌ Not Available"}")
            }
            
            // 3. List available models
            println("\nListing available models...")
            val models = RunAnywhereSDK.shared.listAvailableModels()
            if (models.isEmpty()) {
                println("No models available. Adding a sample model...")
                
                // Add a sample model
                val sampleModel = RunAnywhereSDK.shared.addModelFromURL(
                    name = "GPT-2 Small",
                    url = "https://example.com/gpt2-small.tflite",
                    framework = LLMFramework.TENSORFLOW_LITE,
                    estimatedSize = 500_000_000 // 500MB
                )
                println("Added sample model: ${sampleModel.name}")
            } else {
                models.forEach { model ->
                    println("Model: ${model.name} (${model.format})")
                }
            }
            
            // 4. Load a model
            println("\nLoading model...")
            val modelInfo = RunAnywhereSDK.shared.loadModel("gpt-2-small")
            println("Model loaded: ${modelInfo.name}")
            
            // 5. Generate text
            println("\nGenerating text...")
            val generationOptions = GenerationOptions(
                maxTokens = 50,
                temperature = 0.7f,
                topP = 1.0f,
                context = Context(
                    messages = listOf(
                        Message(
                            role = Message.Role.USER,
                            content = "Hello, how are you?"
                        )
                    ),
                    maxTokens = 2048
                )
            )
            
            val result = RunAnywhereSDK.shared.generate(
                prompt = "Tell me a short story about a robot",
                options = generationOptions
            )
            
            println("Generated text: ${result.text}")
            println("Tokens used: ${result.tokensUsed}")
            println("Latency: ${result.latencyMs}ms")
            println("Execution target: ${result.executionTarget}")
            println("Amount saved: $${result.savedAmount}")
            println("Framework used: ${result.framework?.displayName ?: "Cloud"}")
            
            // 6. Streaming generation
            println("\nGenerating text with streaming...")
            val stream = RunAnywhereSDK.shared.generateStream(
                prompt = "Write a poem about technology",
                options = GenerationOptions(maxTokens = 30)
            )
            
            stream.collect { chunk ->
                print(chunk)
            }
            println() // New line after streaming
            
            // 7. Performance monitoring
            println("\nPerformance monitoring...")
            val monitor = RunAnywhereSDK.shared.performanceMonitor
            println("Performance monitor available: ${monitor != null}")
            
            // 8. Benchmarking
            println("\nBenchmarking...")
            val benchmark = RunAnywhereSDK.shared.benchmarkSuite
            println("Benchmark suite available: ${benchmark != null}")
            
            // 9. A/B Testing
            println("\nA/B Testing...")
            val abTesting = RunAnywhereSDK.shared.abTesting
            println("A/B testing available: ${abTesting != null}")
            
            // 10. Unload model
            println("\nUnloading model...")
            RunAnywhereSDK.shared.unloadModel()
            println("Model unloaded successfully!")
            
            println("\n✅ SDK example completed successfully!")
            
        } catch (e: RunAnywhereError) {
            println("❌ RunAnywhere Error: ${e.message}")
            when (e) {
                is RunAnywhereError.NotInitialized -> {
                    println("Please initialize the SDK first")
                }
                is RunAnywhereError.ModelNotFound -> {
                    println("Model not found. Please check the model identifier")
                }
                is RunAnywhereError.GenerationFailed -> {
                    println("Text generation failed. Please try again")
                }
                is RunAnywhereError.NetworkUnavailable -> {
                    println("Network connection is required for this operation")
                }
                else -> {
                    println("An unexpected error occurred")
                }
            }
        } catch (e: Exception) {
            println("❌ Unexpected error: ${e.message}")
            e.printStackTrace()
        }
    }
    
    /**
     * Example of downloading a model
     */
    fun downloadModelExample() = runBlocking {
        try {
            println("Downloading model example...")
            
            val downloadTask = RunAnywhereSDK.shared.downloadModel("gpt-2-small")
            
            downloadTask.progress.collect { progress ->
                println("Download progress: ${String.format("%.1f", progress.percentage)}%")
                println("Downloaded: ${progress.bytesDownloaded} / ${progress.totalBytes} bytes")
                println("Speed: ${progress.speed} bytes/sec")
                progress.estimatedTimeRemaining?.let { time ->
                    println("ETA: ${time / 1000} seconds")
                }
                println("---")
            }
            
            println("Download completed!")
            
        } catch (e: RunAnywhereError) {
            println("Download failed: ${e.message}")
        }
    }
    
    /**
     * Example of framework adapter registration
     */
    fun frameworkAdapterExample() {
        println("Framework adapter example...")
        
        // Example of registering a custom framework adapter
        // This would be implemented by the user
        /*
        val customAdapter = object : FrameworkAdapter {
            override val framework: LLMFramework = LLMFramework.CUSTOM
            
            override suspend fun isAvailable(): Boolean = true
            
            override suspend fun loadModel(modelInfo: ModelInfo): LoadedModel {
                // Implementation
            }
            
            override suspend fun unloadModel(modelId: String) {
                // Implementation
            }
            
            override suspend fun generate(
                prompt: String,
                options: GenerationOptions
            ): GenerationResult {
                // Implementation
            }
            
            override fun generateStream(
                prompt: String,
                options: GenerationOptions
            ): Flow<String> {
                // Implementation
            }
            
            override fun getSupportedFormats(): List<ModelFormat> = listOf(ModelFormat.CUSTOM)
            
            override fun getHardwareRequirements(): List<HardwareRequirement> = emptyList()
            
            override fun getPerformanceCharacteristics(): PerformanceCharacteristics {
                return PerformanceCharacteristics(
                    maxTokensPerSecond = 10.0,
                    memoryEfficiency = 0.8,
                    batteryEfficiency = 0.7,
                    latency = 100
                )
            }
        }
        
        RunAnywhereSDK.shared.registerFrameworkAdapter(customAdapter)
        */
        
        println("Framework adapter example completed!")
    }
}

/**
 * Main function to run the example
 */
fun main() {
    val example = SDKExample()
    example.runExample()
} 