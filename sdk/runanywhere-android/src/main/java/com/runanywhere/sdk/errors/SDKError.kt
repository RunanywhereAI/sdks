package com.runanywhere.sdk.errors

/**
 * SDK-specific errors
 */
sealed class SDKError : Exception() {
    object NotInitialized : SDKError() {
        override val message: String = "SDK not initialized. Call initialize(with:) first."
    }
    
    object NotImplemented : SDKError() {
        override val message: String = "This feature is not yet implemented."
    }
    
    data class ModelNotFound(val model: String) : SDKError() {
        override val message: String = "Model '$model' not found."
    }
    
    data class LoadingFailed(val reason: String) : SDKError() {
        override val message: String = "Failed to load model: $reason"
    }
    
    data class GenerationFailed(val reason: String) : SDKError() {
        override val message: String = "Generation failed: $reason"
    }
    
    data class FrameworkNotAvailable(val framework: String) : SDKError() {
        override val message: String = "Framework $framework not available"
    }
    
    data class DownloadFailed(val error: Throwable) : SDKError() {
        override val message: String = "Download failed: ${error.message}"
    }
    
    data class ValidationFailed(val error: ValidationError) : SDKError() {
        override val message: String = "Validation failed: ${error.message}"
    }
    
    data class RoutingFailed(val reason: String) : SDKError() {
        override val message: String = "Routing failed: $reason"
    }
}

/**
 * Validation error
 */
data class ValidationError(
    val field: String,
    val message: String,
    val code: String? = null
) 