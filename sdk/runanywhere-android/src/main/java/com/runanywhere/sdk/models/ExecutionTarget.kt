package com.runanywhere.sdk.models

/**
 * Execution target for model inference
 */
enum class ExecutionTarget {
    /**
     * Execute on device
     */
    ON_DEVICE,
    
    /**
     * Execute in the cloud
     */
    CLOUD,
    
    /**
     * Hybrid execution (partial on-device, partial cloud)
     */
    HYBRID
} 