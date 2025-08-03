package com.runanywhere.sdk.models

/**
 * Hardware configuration for framework adapters
 */
data class HardwareConfiguration(
    var primaryAccelerator: HardwareAcceleration = HardwareAcceleration.AUTO,
    var fallbackAccelerator: HardwareAcceleration? = HardwareAcceleration.CPU,
    var memoryMode: MemoryMode = MemoryMode.BALANCED,
    var threadCount: Int = Runtime.getRuntime().availableProcessors(),
    var useQuantization: Boolean = false,
    var quantizationBits: Int = 8
) {
    enum class MemoryMode {
        CONSERVATIVE,
        BALANCED,
        AGGRESSIVE
    }
} 