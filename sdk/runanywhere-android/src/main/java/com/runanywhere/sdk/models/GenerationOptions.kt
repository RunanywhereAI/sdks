package com.runanywhere.sdk.models

/**
 * Options for text generation
 */
data class GenerationOptions(
    /**
     * Maximum number of tokens to generate
     */
    val maxTokens: Int = 100,
    
    /**
     * Temperature for sampling (0.0 - 1.0)
     */
    val temperature: Float = 0.7f,
    
    /**
     * Top-p sampling parameter
     */
    val topP: Float = 1.0f,
    
    /**
     * Context for the generation
     */
    val context: Context? = null,
    
    /**
     * Enable real-time tracking for cost dashboard
     */
    val enableRealTimeTracking: Boolean = true,
    
    /**
     * Stop sequences
     */
    val stopSequences: List<String> = emptyList(),
    
    /**
     * Seed for reproducible generation
     */
    val seed: Int? = null,
    
    /**
     * Enable streaming mode
     */
    val streamingEnabled: Boolean = false,
    
    /**
     * Token budget constraint (for cost control)
     */
    val tokenBudget: TokenBudget? = null,
    
    /**
     * Framework-specific options
     */
    val frameworkOptions: FrameworkOptions? = null,
    
    /**
     * Preferred execution target
     */
    val preferredExecutionTarget: ExecutionTarget? = null
)

/**
 * Context for maintaining conversation state
 */
data class Context(
    /**
     * Previous messages in the conversation
     */
    val messages: List<Message> = emptyList(),
    
    /**
     * System prompt override
     */
    val systemPrompt: String? = null,
    
    /**
     * Maximum context window size
     */
    val maxTokens: Int = 2048
)

/**
 * Message in a conversation
 */
data class Message(
    /**
     * Role of the message sender
     */
    val role: Role,
    
    /**
     * Content of the message
     */
    val content: String,
    
    /**
     * Timestamp
     */
    val timestamp: Long = System.currentTimeMillis()
) {
    enum class Role {
        USER,
        ASSISTANT,
        SYSTEM
    }
}

/**
 * Token budget for cost control
 */
data class TokenBudget(
    val maxTokens: Int,
    val costLimit: Double? = null
)

/**
 * Framework-specific options
 */
data class FrameworkOptions(
    val tensorFlowLiteOptions: TensorFlowLiteOptions? = null,
    val onnxOptions: OnnxOptions? = null,
    val llamaCppOptions: LlamaCppOptions? = null
)

/**
 * TensorFlow Lite specific options
 */
data class TensorFlowLiteOptions(
    val useNNAPI: Boolean = false,
    val useGPU: Boolean = false,
    val numThreads: Int = 4
)

/**
 * ONNX specific options
 */
data class OnnxOptions(
    val executionProvider: String = "CPUExecutionProvider",
    val graphOptimizationLevel: Int = 99
)

/**
 * Llama.cpp specific options
 */
data class LlamaCppOptions(
    val nCtx: Int = 2048,
    val nThreads: Int = 4,
    val nGpuLayers: Int = 0
) 