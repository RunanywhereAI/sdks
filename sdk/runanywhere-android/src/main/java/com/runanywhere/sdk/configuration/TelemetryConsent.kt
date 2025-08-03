package com.runanywhere.sdk.configuration

/**
 * Telemetry consent preference
 */
enum class TelemetryConsent {
    /**
     * Telemetry is granted
     */
    GRANTED,
    
    /**
     * Telemetry is denied
     */
    DENIED,
    
    /**
     * Telemetry consent not yet determined
     */
    NOT_DETERMINED
} 