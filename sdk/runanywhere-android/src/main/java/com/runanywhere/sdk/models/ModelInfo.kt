package com.runanywhere.sdk.models

import java.io.File
import java.net.URL

/**
 * Information about a model
 */
data class ModelInfo(
    val id: String,
    val name: String,
    val format: ModelFormat,
    val downloadURL: URL? = null,
    var localPath: File? = null,
    val estimatedMemory: Long = 1_000_000_000, // 1GB default
    val contextLength: Int = 2048,
    val downloadSize: Long? = null,
    val checksum: String? = null,
    val compatibleFrameworks: List<LLMFramework> = emptyList(),
    val preferredFramework: LLMFramework? = null,
    val hardwareRequirements: List<HardwareRequirement> = emptyList(),
    val tokenizerFormat: TokenizerFormat? = null,
    val metadata: ModelInfoMetadata? = null,
    val alternativeDownloadURLs: List<URL>? = null,
    val additionalProperties: Map<String, Any> = emptyMap()
)

/**
 * Hardware requirement for a model
 */
data class HardwareRequirement(
    val type: HardwareType,
    val minimumSpecification: String,
    val recommendedSpecification: String? = null
)

/**
 * Hardware types
 */
enum class HardwareType {
    CPU,
    GPU,
    NPU,
    MEMORY,
    STORAGE
}

/**
 * Tokenizer format
 */
enum class TokenizerFormat {
    SENTENCEPIECE,
    BPE,
    WORDPIECE,
    UNKNOWN
}

/**
 * Model metadata
 */
data class ModelInfoMetadata(
    val version: String? = null,
    val description: String? = null,
    val author: String? = null,
    val license: String? = null,
    val tags: List<String> = emptyList(),
    val lastUsed: Long? = null,
    val downloadDate: Long? = null
) 