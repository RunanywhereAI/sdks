package com.runanywhere.sdk.models

/**
 * Result of a text generation request
 */
data class GenerationResult(
    /**
     * Generated text
     */
    val text: String,
    
    /**
     * Number of tokens used
     */
    val tokensUsed: Int,
    
    /**
     * Model used for generation
     */
    val modelUsed: String,
    
    /**
     * Latency in milliseconds
     */
    val latencyMs: Long,
    
    /**
     * Execution target (device/cloud/hybrid)
     */
    val executionTarget: ExecutionTarget,
    
    /**
     * Amount saved by using on-device execution
     */
    val savedAmount: Double,
    
    /**
     * Framework used for generation (if on-device)
     */
    val framework: LLMFramework? = null,
    
    /**
     * Hardware acceleration used
     */
    val hardwareUsed: HardwareAcceleration = HardwareAcceleration.CPU,
    
    /**
     * Memory used during generation (in bytes)
     */
    val memoryUsed: Long = 0,
    
    /**
     * Tokenizer format used
     */
    val tokenizerFormat: TokenizerFormat? = null,
    
    /**
     * Detailed performance metrics
     */
    val performanceMetrics: PerformanceMetrics,
    
    /**
     * Additional metadata
     */
    val metadata: ResultMetadata? = null
)

/**
 * Result metadata for additional strongly-typed information
 */
data class ResultMetadata(
    val routingReason: RoutingReasonType,
    val fallbackUsed: Boolean = false,
    val cacheHit: Boolean = false,
    val modelVersion: String? = null,
    val experimentId: String? = null,
    val debugInfo: DebugInfo? = null
)

/**
 * Strongly typed routing reason
 */
enum class RoutingReasonType {
    USER_PREFERENCE,
    COST_OPTIMIZATION,
    PERFORMANCE_OPTIMIZATION,
    RESOURCE_CONSTRAINT,
    POLICY_DRIVEN,
    FALLBACK,
    EXPERIMENTAL
}

/**
 * Debug information for development
 */
data class DebugInfo(
    val startTime: Long,
    val endTime: Long,
    val threadCount: Int,
    val deviceLoad: DeviceLoadLevel
)

/**
 * Device load level
 */
enum class DeviceLoadLevel {
    IDLE,       // 0-20%
    LOW,        // 20-40%
    MODERATE,   // 40-60%
    HIGH,       // 60-80%
    CRITICAL;   // 80-100%
    
    companion object {
        fun fromPercentage(percentage: Double): DeviceLoadLevel {
            return when {
                percentage < 0.2 -> IDLE
                percentage < 0.4 -> LOW
                percentage < 0.6 -> MODERATE
                percentage < 0.8 -> HIGH
                else -> CRITICAL
            }
        }
    }
}

/**
 * Performance metrics
 */
data class PerformanceMetrics(
    val inferenceTime: Long,
    val tokenizationTime: Long,
    val totalTime: Long,
    val tokensPerSecond: Double,
    val memoryPeak: Long,
    val cpuUsage: Double,
    val gpuUsage: Double? = null
) 