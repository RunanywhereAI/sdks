package com.runanywhere.sdk.models

/**
 * Detailed information about framework availability
 */
data class FrameworkAvailability(
    /**
     * The framework being described
     */
    val framework: LLMFramework,
    
    /**
     * Whether this framework is available (has a registered adapter)
     */
    val isAvailable: Boolean,
    
    /**
     * Reason why the framework is not available (if applicable)
     */
    val unavailabilityReason: String? = null,
    
    /**
     * Hardware requirements for optimal performance
     */
    val requirements: List<HardwareRequirement> = emptyList(),
    
    /**
     * Recommended use cases for this framework
     */
    val recommendedFor: List<String> = emptyList(),
    
    /**
     * Model formats supported by this framework
     */
    val supportedFormats: List<ModelFormat> = emptyList()
) 