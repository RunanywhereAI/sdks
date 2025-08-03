package com.runanywhere.sdk.services

import com.runanywhere.sdk.models.ModelInfo
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.ObjectInputStream
import java.io.ObjectOutputStream
import java.io.Serializable

/**
 * Model metadata store for persisting model information
 */
class ModelMetadataStore {
    private val metadataFile = File("model_metadata.dat")
    private val metadata = mutableMapOf<String, ModelMetadata>()
    
    init {
        loadMetadata()
    }
    
    /**
     * Update last used timestamp for a model
     */
    fun updateLastUsed(modelId: String) {
        val currentTime = System.currentTimeMillis()
        val modelMetadata = metadata.getOrPut(modelId) { ModelMetadata(modelId) }
        modelMetadata.lastUsed = currentTime
        saveMetadata()
    }
    
    /**
     * Load stored models
     */
    fun loadStoredModels(): List<ModelInfo> {
        // This would typically load from persistent storage
        // For now, return empty list
        return emptyList()
    }
    
    private fun loadMetadata() {
        if (metadataFile.exists()) {
            try {
                FileInputStream(metadataFile).use { fis ->
                    ObjectInputStream(fis).use { ois ->
                        @Suppress("UNCHECKED_CAST")
                        val loadedMetadata = ois.readObject() as? Map<String, ModelMetadata>
                        if (loadedMetadata != null) {
                            metadata.clear()
                            metadata.putAll(loadedMetadata)
                        }
                    }
                }
            } catch (e: Exception) {
                // Handle loading error
            }
        }
    }
    
    private fun saveMetadata() {
        try {
            FileOutputStream(metadataFile).use { fos ->
                ObjectOutputStream(fos).use { oos ->
                    oos.writeObject(metadata.toMap())
                }
            }
        } catch (e: Exception) {
            // Handle saving error
        }
    }
}

/**
 * Model metadata for persistence
 */
data class ModelMetadata(
    val modelId: String,
    var lastUsed: Long? = null,
    var downloadDate: Long? = null,
    var usageCount: Int = 0,
    var averageLatency: Long = 0
) : Serializable 