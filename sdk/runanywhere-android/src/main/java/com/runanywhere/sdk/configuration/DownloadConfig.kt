package com.runanywhere.sdk.configuration

import java.io.File

/**
 * Download configuration
 */
data class DownloadConfig(
    /**
     * Maximum concurrent downloads
     */
    val maxConcurrentDownloads: Int = 2,
    
    /**
     * Number of retry attempts
     */
    val retryAttempts: Int = 3,
    
    /**
     * Custom cache directory
     */
    val cacheDirectory: File? = null,
    
    /**
     * Download timeout in seconds
     */
    val timeoutInterval: Long = 300
) 