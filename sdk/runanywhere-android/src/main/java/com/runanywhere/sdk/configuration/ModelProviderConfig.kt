package com.runanywhere.sdk.configuration

/**
 * Model provider configuration
 */
data class ModelProviderConfig(
    /**
     * Provider name (e.g., "HuggingFace", "Kaggle")
     */
    val provider: String,
    
    /**
     * Authentication credentials
     */
    val credentials: ProviderCredentials? = null,
    
    /**
     * Whether this provider is enabled
     */
    val enabled: Boolean = true
)

/**
 * Provider credentials
 */
data class ProviderCredentials(
    val apiKey: String? = null,
    val username: String? = null,
    val password: String? = null,
    val token: String? = null
) 