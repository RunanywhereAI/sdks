package com.runanywhere.sdk.models

/**
 * Model formats supported
 */
enum class ModelFormat {
    TFLITE,
    ONNX,
    ORT,
    SAFETENSORS,
    GGUF,
    GGML,
    PTE,
    BIN,
    WEIGHTS,
    CHECKPOINT,
    UNKNOWN;
    
    companion object {
        fun fromString(value: String): ModelFormat {
            return values().find { it.name.equals(value, ignoreCase = true) } ?: UNKNOWN
        }
    }
} 