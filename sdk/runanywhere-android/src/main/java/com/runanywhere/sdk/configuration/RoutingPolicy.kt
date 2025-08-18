package com.runanywhere.sdk.configuration

/**
 * Routing policy for model selection
 */
enum class RoutingPolicy {
    /**
     * Automatic routing based on device capabilities and model requirements
     */
    AUTOMATIC,
    
    /**
     * Always prefer on-device execution
     */
    ON_DEVICE_ONLY,
    
    /**
     * Always prefer cloud execution
     */
    CLOUD_ONLY,
    
    /**
     * Hybrid routing with fallback
     */
    HYBRID
} 