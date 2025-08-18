package com.runanywhere.sdk.services

import com.runanywhere.sdk.models.*
import kotlinx.coroutines.flow.Flow

/**
 * Framework adapter interface
 */
interface FrameworkAdapter {
    /**
     * The framework this adapter supports
     */
    val framework: LLMFramework
    
    /**
     * Check if this framework is available on the current device
     */
    suspend fun isAvailable(): Boolean
    
    /**
     * Load a model
     */
    suspend fun loadModel(modelInfo: ModelInfo): LoadedModel
    
    /**
     * Unload a model
     */
    suspend fun unloadModel(modelId: String)
    
    /**
     * Generate text
     */
    suspend fun generate(
        prompt: String,
        options: GenerationOptions
    ): GenerationResult
    
    /**
     * Generate text as a stream
     */
    fun generateStream(
        prompt: String,
        options: GenerationOptions
    ): Flow<String>
    
    /**
     * Get supported model formats
     */
    fun getSupportedFormats(): List<ModelFormat>
    
    /**
     * Get hardware requirements
     */
    fun getHardwareRequirements(): List<HardwareRequirement>
    
    /**
     * Get performance characteristics
     */
    fun getPerformanceCharacteristics(): PerformanceCharacteristics
}

/**
 * Performance characteristics for a framework
 */
data class PerformanceCharacteristics(
    val maxTokensPerSecond: Double,
    val memoryEfficiency: Double, // 0.0 to 1.0
    val batteryEfficiency: Double, // 0.0 to 1.0
    val latency: Long // milliseconds
) 