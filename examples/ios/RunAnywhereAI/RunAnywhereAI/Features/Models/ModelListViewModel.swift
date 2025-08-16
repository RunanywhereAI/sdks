//
//  ModelListViewModel.swift
//  RunAnywhereAI
//
//  Simplified version that uses SDK directly
//

import Foundation
import SwiftUI
import RunAnywhereSDK

@MainActor
class ModelListViewModel: ObservableObject {
    static let shared = ModelListViewModel()

    @Published var availableModels: [ModelInfo] = []
    @Published var currentModel: ModelInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let sdk = RunAnywhereSDK.shared

    // MARK: - Predefined Models
    private let predefinedModels: [ModelInfo] = [
        // Apple Foundation Models (Built-in, no download required)
        ModelInfo(
            id: "apple-foundation-base",
            name: "Apple Foundation Model",
            format: .mlmodel,
            downloadURL: nil, // Built-in model
            localPath: URL(fileURLWithPath: "/System/Library/PrivateFrameworks/"), // System framework
            estimatedMemory: 500_000_000, // 500MB estimate
            contextLength: 4096,
            downloadSize: 0, // No download needed
            compatibleFrameworks: [.foundationModels],
            preferredFramework: .foundationModels,
            supportsThinking: false
        ),
        
        // Llama-3.2 1B Q6_K
        ModelInfo(
            id: "llama-3.2-1b-instruct-q6-k",
            name: "Llama 3.2 1B Instruct Q6_K",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q6_K.gguf"),
            estimatedMemory: 1_200_000_000, // 1.2GB
            contextLength: 131072,
            downloadSize: 750_000_000, // ~750MB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: true
        ),

        // SmolLM2 1.7B Instruct Q6_K_L
        ModelInfo(
            id: "smollm2-1.7b-instruct-q6-k-l",
            name: "SmolLM2 1.7B Instruct Q6_K_L",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/bartowski/SmolLM2-1.7B-Instruct-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Q6_K_L.gguf"),
            estimatedMemory: 1_800_000_000, // 1.8GB
            contextLength: 8192,
            downloadSize: 1_300_000_000, // ~1.3GB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: true
        ),

        // Qwen-2.5 0.5B Q6_K
        ModelInfo(
            id: "qwen-2.5-0.5b-instruct-q6-k",
            name: "Qwen 2.5 0.5B Instruct Q6_K",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/Triangle104/Qwen2.5-0.5B-Instruct-Q6_K-GGUF/resolve/main/qwen2.5-0.5b-instruct-q6_k.gguf"),
            estimatedMemory: 600_000_000, // 600MB
            contextLength: 32768,
            downloadSize: 400_000_000, // ~400MB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: true
        ),

        // SmolLM2 360M Q8_0
        ModelInfo(
            id: "smollm2-360m-q8-0",
            name: "SmolLM2 360M Q8_0",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/prithivMLmods/SmolLM2-360M-GGUF/resolve/main/SmolLM2-360M.Q8_0.gguf"),
            estimatedMemory: 500_000_000, // 500MB
            contextLength: 8192,
            downloadSize: 380_000_000, // ~380MB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: false
        ),

        // Qwen-2.5 1.5B Q6_K
        ModelInfo(
            id: "qwen-2.5-1.5b-instruct-q6-k",
            name: "Qwen 2.5 1.5B Instruct Q6_K",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/ZeroWw/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct.q6_k.gguf"),
            estimatedMemory: 1_600_000_000, // 1.6GB
            contextLength: 32768,
            downloadSize: 1_100_000_000, // ~1.1GB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: true
        ),

        // Qwen3 600M Q8_0
        ModelInfo(
            id: "qwen3-600m-instruct-q8-0",
            name: "Qwen3 600M Instruct Q8_0",
            format: .gguf,
            downloadURL: URL(string: "https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf"),
            estimatedMemory: 800_000_000, // 800MB
            contextLength: 32768,
            downloadSize: 650_000_000, // ~650MB
            compatibleFrameworks: [.llamaCpp],
            preferredFramework: .llamaCpp,
            supportsThinking: true
        )
    ]

    init() {
        print("🎯 DEBUG: ModelListViewModel.init() called")
        Task {
            print("🎯 DEBUG: Starting loadModels() task")
            await loadModels()
            print("🎯 DEBUG: loadModels() task completed")
        }
    }

    func loadModels() async {
        print("🎯 DEBUG: loadModels() started")
        isLoading = true
        errorMessage = nil

        // First, register predefined models with SDK if they have download URLs
        await registerPredefinedModels()

        // Start with predefined models
        var allModels = predefinedModels
        print("🎯 DEBUG: Starting with \(allModels.count) predefined models")
        for model in predefinedModels {
            print("🎯 DEBUG: Predefined model: \(model.name), frameworks: \(model.compatibleFrameworks), downloadURL: \(model.downloadURL?.absoluteString ?? "nil")")
        }

        do {
            // Add any existing SDK models
            let sdkModels = try await sdk.listAvailableModels()
            print("🎯 DEBUG: SDK returned \(sdkModels.count) models")
            
            for sdkModel in sdkModels {
                print("🎯 DEBUG: SDK model: \(sdkModel.name), frameworks: \(sdkModel.compatibleFrameworks)")
            }

            // Avoid duplicates by checking if model already exists in predefined list
            for sdkModel in sdkModels {
                if !allModels.contains(where: { $0.id == sdkModel.id }) {
                    allModels.append(sdkModel)
                    print("🎯 DEBUG: Added SDK model to allModels: \(sdkModel.name)")
                } else {
                    print("🎯 DEBUG: Skipped duplicate SDK model: \(sdkModel.name)")
                }
            }
        } catch {
            print("❌ Failed to load models from SDK: \(error)")
            // Still proceed with predefined models even if SDK fails
        }

        availableModels = allModels
        
        print("🎯 DEBUG: Looking for Foundation Models in \(allModels.count) total models")
        for model in allModels {
            print("🎯 DEBUG: Model: \(model.name), frameworks: \(model.compatibleFrameworks)")
        }
        
        // Auto-select best available model
        // Try Foundation Models first (only on real devices)
        #if targetEnvironment(simulator)
        print("🎯 DEBUG: Running in simulator - Foundation Models not available, selecting alternative")
        let foundationModel: ModelInfo? = nil
        #else
        let foundationModel = allModels.first(where: { $0.compatibleFrameworks.contains(.foundationModels) })
        if foundationModel != nil {
            print("🎯 DEBUG: Found Foundation Model on real device: \(foundationModel!.name)")
        }
        #endif
        
        if let foundationModel = foundationModel {
            print("🎯 DEBUG: Selecting Foundation Model: \(foundationModel.name)")
            currentModel = foundationModel
            // Foundation Models don't need downloading - they're built-in
            // Just load them directly in the SDK
            Task {
                do {
                    print("🎯 DEBUG: Loading Foundation Model in SDK...")
                    
                    // For Foundation Models, we still need to load them through SDK
                    // even though they're built-in - the SDK needs to initialize them
                    print("🎯 DEBUG: About to load Foundation Model '\(foundationModel.name)' with ID '\(foundationModel.id)'")
                    print("🎯 DEBUG: Foundation Model format: \(foundationModel.format)")
                    print("🎯 DEBUG: Foundation Model frameworks: \(foundationModel.compatibleFrameworks)")
                    
                    try await sdk.loadModel(foundationModel.id)
                    print("🎯 DEBUG: Foundation Model loaded successfully in SDK!")
                    // Post notification that model was loaded
                    await MainActor.run {
                        NotificationCenter.default.post(name: Notification.Name("ModelLoaded"), object: foundationModel)
                        print("🎯 DEBUG: Posted ModelLoaded notification for Foundation Model")
                    }
                } catch {
                    print("❌ Failed to load Foundation Model: \(error)")
                    await MainActor.run {
                        self.currentModel = nil
                    }
                }
            }
        } else {
            print("❌ DEBUG: No Foundation Model found - trying alternative models")
            // Fallback to any available model
            if let alternativeModel = allModels.first {
                print("🎯 DEBUG: Selecting alternative model: \(alternativeModel.name)")
                currentModel = alternativeModel
            } else {
                print("❌ DEBUG: No models available at all")
                currentModel = nil
            }
        }
        
        isLoading = false
    }

    private func registerPredefinedModels() async {
        for model in predefinedModels {
            do {
                // Check if model is already registered by trying to get it
                let existingModels = try await sdk.listAvailableModels()
                let alreadyRegistered = existingModels.contains { $0.id == model.id }

                if !alreadyRegistered {
                    if let downloadURL = model.downloadURL {
                        // Register downloadable model with SDK
                        let _ = sdk.addModelFromURL(
                            name: model.name,
                            url: downloadURL,
                            framework: model.preferredFramework ?? .llamaCpp,
                            estimatedSize: model.downloadSize,
                            supportsThinking: model.supportsThinking
                        )
                        print("🎯 DEBUG: Registered downloadable model: \(model.name)")
                    } else if model.compatibleFrameworks.contains(.foundationModels) {
                        // For Foundation Models, register them as local models without download URL
                        print("🎯 DEBUG: Registering Foundation Model as local model: \(model.name)")
                        // We'll try to register it as a local model
                        // This might require a different SDK method for built-in models
                    }
                } else {
                    print("🎯 DEBUG: Model \(model.name) already registered, skipping")
                }
            } catch {
                print("❌ Failed to register predefined model \(model.name): \(error)")
                // Continue with other models even if one fails
            }
        }
    }

    func selectModel(_ model: ModelInfo) async {
        isLoading = true
        errorMessage = nil

        do {
            // Direct SDK usage
            try await sdk.loadModel(model.id)
            currentModel = model

            // Post notification that model was loaded
            await MainActor.run {
                NotificationCenter.default.post(name: Notification.Name("ModelLoaded"), object: model)
            }
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshModels() async {
        await loadModels()
    }

    func addImportedModel(_ model: ModelInfo) async {
        availableModels.append(model)
    }

    func setCurrentModel(_ model: ModelInfo) async {
        currentModel = model
    }

    func downloadModel(_ modelId: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await sdk.downloadModel(modelId)
            // Wait a moment for filesystem to settle
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            // Refresh models to update download status
            await loadModels()
            return true
        } catch {
            errorMessage = "Failed to download model: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteModel(_ modelId: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await sdk.deleteModel(modelId)
            // Refresh models to update list
            await loadModels()
            return true
        } catch {
            errorMessage = "Failed to delete model: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
