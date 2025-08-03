package com.runanywhere.sdk.models

/**
 * Criteria for filtering models
 */
data class ModelCriteria(
    val framework: LLMFramework? = null,
    val format: ModelFormat? = null,
    val maxMemory: Long? = null,
    val minContextLength: Int? = null,
    val tags: List<String> = emptyList(),
    val downloaded: Boolean? = null
) 