package com.runanywhere.sdk.models

/**
 * Cost breakdown for generation
 */
data class CostBreakdown(
    /**
     * Total cost in USD
     */
    val totalCost: Double,
    
    /**
     * Savings achieved by using on-device execution
     */
    val savingsAchieved: Double,
    
    /**
     * Cloud cost if it had been used
     */
    val cloudCost: Double? = null,
    
    /**
     * Device execution cost
     */
    val deviceCost: Double? = null
) 