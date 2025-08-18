package com.runanywhere.sdk.models

import kotlinx.coroutines.flow.Flow

/**
 * Download task for model downloads
 */
data class DownloadTask(
    val id: String,
    val modelId: String,
    val status: DownloadStatus,
    val progress: Flow<DownloadProgress>,
    val cancel: () -> Unit
)

/**
 * Download status
 */
enum class DownloadStatus {
    PENDING,
    DOWNLOADING,
    COMPLETED,
    FAILED,
    CANCELLED
}

/**
 * Download progress
 */
data class DownloadProgress(
    val bytesDownloaded: Long,
    val totalBytes: Long,
    val percentage: Float,
    val speed: Long, // bytes per second
    val estimatedTimeRemaining: Long? = null // milliseconds
) 