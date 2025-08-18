package com.runanywhere.sdk.models

/**
 * Supported LLM frameworks
 */
enum class LLMFramework(val displayName: String) {
    TENSORFLOW_LITE("TensorFlow Lite"),
    ONNX("ONNX Runtime"),
    EXECUTORCH("ExecuTorch"),
    LLAMACPP("llama.cpp"),
    FOUNDATION_MODELS("Foundation Models"),
    PICOLLM("Pico LLM"),
    MLC("MLC"),
    MEDIAPIPE("MediaPipe"),
    NCNN("NCNN"),
    OPENVINO("OpenVINO"),
    TFLITE_GPU("TensorFlow Lite GPU"),
    TFLITE_NNAPI("TensorFlow Lite NNAPI");
    
    companion object {
        fun fromString(value: String): LLMFramework? {
            return values().find { it.name.equals(value, ignoreCase = true) }
        }
    }
} 