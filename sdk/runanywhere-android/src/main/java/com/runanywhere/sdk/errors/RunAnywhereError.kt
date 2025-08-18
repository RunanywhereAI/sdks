package com.runanywhere.sdk.errors

/**
 * Main public error type for the RunAnywhere SDK
 */
sealed class RunAnywhereError : Exception() {
    // Initialization errors
    object NotInitialized : RunAnywhereError() {
        override val message: String = "RunAnywhere SDK is not initialized. Call initialize() first."
    }
    
    object AlreadyInitialized : RunAnywhereError() {
        override val message: String = "RunAnywhere SDK is already initialized."
    }
    
    data class InvalidConfiguration(val detail: String) : RunAnywhereError() {
        override val message: String = "Invalid configuration: $detail"
    }
    
    object InvalidAPIKey : RunAnywhereError() {
        override val message: String = "Invalid or missing API key."
    }
    
    // Model errors
    data class ModelNotFound(val identifier: String) : RunAnywhereError() {
        override val message: String = "Model '$identifier' not found."
    }
    
    data class ModelLoadFailed(val identifier: String, val error: Throwable?) : RunAnywhereError() {
        override val message: String = if (error != null) {
            "Failed to load model '$identifier': ${error.message}"
        } else {
            "Failed to load model '$identifier'"
        }
    }
    
    data class ModelValidationFailed(val identifier: String, val errors: List<ValidationError>) : RunAnywhereError() {
        override val message: String = "Model '$identifier' validation failed: ${errors.joinToString(", ") { it.message }}"
    }
    
    data class ModelIncompatible(val identifier: String, val reason: String) : RunAnywhereError() {
        override val message: String = "Model '$identifier' is incompatible: $reason"
    }
    
    // Generation errors
    data class GenerationFailed(val reason: String) : RunAnywhereError() {
        override val message: String = "Text generation failed: $reason"
    }
    
    object GenerationTimeout : RunAnywhereError() {
        override val message: String = "Text generation timed out."
    }
    
    data class ContextTooLong(val provided: Int, val maximum: Int) : RunAnywhereError() {
        override val message: String = "Context too long: $provided tokens (maximum: $maximum)"
    }
    
    data class TokenLimitExceeded(val requested: Int, val maximum: Int) : RunAnywhereError() {
        override val message: String = "Token limit exceeded: requested $requested, maximum $maximum"
    }
    
    data class CostLimitExceeded(val estimated: Double, val limit: Double) : RunAnywhereError() {
        override val message: String = "Cost limit exceeded: estimated $${String.format("%.2f", estimated)}, limit $${String.format("%.2f", limit)}"
    }
    
    // Network errors
    object NetworkUnavailable : RunAnywhereError() {
        override val message: String = "Network connection unavailable."
    }
    
    data class RequestFailed(val error: Throwable) : RunAnywhereError() {
        override val message: String = "Request failed: ${error.message}"
    }
    
    data class DownloadFailed(val url: String, val error: Throwable?) : RunAnywhereError() {
        override val message: String = if (error != null) {
            "Failed to download from '$url': ${error.message}"
        } else {
            "Failed to download from '$url'"
        }
    }
    
    // Storage errors
    data class InsufficientStorage(val required: Long, val available: Long) : RunAnywhereError() {
        override val message: String = "Insufficient storage: ${formatBytes(required)} required, ${formatBytes(available)} available"
    }
    
    object StorageFull : RunAnywhereError() {
        override val message: String = "Device storage is full."
    }
    
    // Hardware errors
    data class HardwareUnsupported(val feature: String) : RunAnywhereError() {
        override val message: String = "Hardware does not support $feature."
    }
    
    object MemoryPressure : RunAnywhereError() {
        override val message: String = "System is under memory pressure."
    }
    
    object ThermalStateExceeded : RunAnywhereError() {
        override val message: String = "Device temperature too high for operation."
    }
    
    // Feature errors
    data class FeatureNotAvailable(val feature: String) : RunAnywhereError() {
        override val message: String = "Feature '$feature' is not available."
    }
    
    data class NotImplemented(val feature: String) : RunAnywhereError() {
        override val message: String = "Feature '$feature' is not yet implemented."
    }
    
    companion object {
        private fun formatBytes(bytes: Long): String {
            val units = arrayOf("B", "KB", "MB", "GB", "TB")
            var size = bytes.toDouble()
            var unitIndex = 0
            
            while (size >= 1024 && unitIndex < units.size - 1) {
                size /= 1024
                unitIndex++
            }
            
            return String.format("%.1f %s", size, units[unitIndex])
        }
    }
} 