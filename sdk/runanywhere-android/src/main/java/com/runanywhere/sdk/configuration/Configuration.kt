package com.runanywhere.sdk.configuration

import com.runanywhere.sdk.models.LLMFramework
import com.runanywhere.sdk.models.HardwareConfiguration
import java.net.URL

/**
 * SDK Configuration
 */
data class Configuration(
    /**
     * API key for authentication
     */
    val apiKey: String,
    
    /**
     * Base URL for API requests
     */
    var baseURL: URL = URL("https://api.runanywhere.ai"),
    
    /**
     * Enable real-time dashboard updates
     */
    var enableRealTimeDashboard: Boolean = true,
    
    /**
     * Routing policy for model selection
     */
    var routingPolicy: RoutingPolicy = RoutingPolicy.AUTOMATIC,
    
    /**
     * Telemetry consent
     */
    var telemetryConsent: TelemetryConsent = TelemetryConsent.GRANTED,
    
    /**
     * Privacy mode settings
     */
    var privacyMode: PrivacyMode = PrivacyMode.STANDARD,
    
    /**
     * Debug mode flag
     */
    var debugMode: Boolean = false,
    
    /**
     * Preferred frameworks for model execution
     */
    var preferredFrameworks: List<LLMFramework> = emptyList(),
    
    /**
     * Hardware preferences for model execution
     */
    var hardwarePreferences: HardwareConfiguration? = null,
    
    /**
     * Model provider configurations
     */
    var modelProviders: List<ModelProviderConfig> = emptyList(),
    
    /**
     * Memory threshold for model loading (in bytes)
     */
    var memoryThreshold: Long = 500_000_000, // 500MB default
    
    /**
     * Download configuration
     */
    var downloadConfiguration: DownloadConfig = DownloadConfig()
) {
    /**
     * Convenience constructor for minimal config
     */
    constructor(
        apiKey: String,
        enableRealTimeDashboard: Boolean = true,
        telemetryConsent: TelemetryConsent = TelemetryConsent.GRANTED
    ) : this(
        apiKey = apiKey,
        baseURL = URL("https://api.runanywhere.ai"),
        enableRealTimeDashboard = enableRealTimeDashboard,
        routingPolicy = RoutingPolicy.AUTOMATIC,
        telemetryConsent = telemetryConsent,
        privacyMode = PrivacyMode.STANDARD,
        debugMode = false,
        preferredFrameworks = emptyList(),
        hardwarePreferences = null,
        modelProviders = emptyList(),
        memoryThreshold = 500_000_000,
        downloadConfiguration = DownloadConfig()
    )
} 