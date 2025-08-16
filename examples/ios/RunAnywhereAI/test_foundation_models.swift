#!/usr/bin/env swift

// Test script for Foundation Models integration
// Run with: swift test_foundation_models.swift

import Foundation
import RunAnywhereSDK

// Test function
func testFoundationModels() async {
    print("🧪 Testing Foundation Models Integration")
    print("=" * 50)
    
    do {
        // 1. Initialize SDK
        print("\n1️⃣ Initializing SDK...")
        let config = Configuration(
            apiKey: "test-key",
            enableRealTimeDashboard: false,
            telemetryConsent: .granted
        )
        
        try await RunAnywhereSDK.shared.initialize(configuration: config)
        print("✅ SDK initialized")
        
        // 2. Register Foundation Models adapter
        print("\n2️⃣ Registering Foundation Models adapter...")
        if #available(iOS 17.0, macOS 14.0, *) {
            let adapter = FoundationModelsAdapter()
            RunAnywhereSDK.shared.registerFrameworkAdapter(adapter)
            print("✅ Foundation Models adapter registered")
        } else {
            print("⚠️ Foundation Models requires iOS 17.0+ / macOS 14.0+")
            return
        }
        
        // 3. Check framework availability
        print("\n3️⃣ Checking framework availability...")
        let availability = await RunAnywhereSDK.shared.getFrameworkAvailability()
        
        if let foundationModelsAvailability = availability.first(where: { $0.framework == .foundationModels }) {
            print("Foundation Models Available: \(foundationModelsAvailability.isAvailable)")
            if !foundationModelsAvailability.isAvailable {
                print("Reason: \(foundationModelsAvailability.unavailabilityReason ?? "Unknown")")
            }
        }
        
        // 4. List available models
        print("\n4️⃣ Listing available models...")
        let models = try await RunAnywhereSDK.shared.listAvailableModels()
        
        let foundationModels = models.filter { $0.compatibleFrameworks.contains(.foundationModels) }
        print("Found \(foundationModels.count) Foundation Model(s)")
        
        for model in foundationModels {
            print("  - \(model.name) (ID: \(model.id))")
        }
        
        // 5. Test loading a Foundation Model (if available)
        if let firstModel = foundationModels.first {
            print("\n5️⃣ Testing model loading...")
            print("Loading model: \(firstModel.name)")
            
            try await RunAnywhereSDK.shared.loadModel(firstModel.id)
            print("✅ Model loaded successfully")
            
            // 6. Test generation
            print("\n6️⃣ Testing text generation...")
            let prompt = "Hello, what can you tell me about Apple's on-device AI?"
            
            let result = try await RunAnywhereSDK.shared.generate(
                prompt: prompt,
                options: GenerationOptions()
            )
            
            print("Prompt: \(prompt)")
            print("Response: \(result.text)")
            print("Tokens used: \(result.tokensUsed)")
            print("Generation time: \(result.generationTime)s")
            
            // 7. Unload model
            print("\n7️⃣ Unloading model...")
            try await RunAnywhereSDK.shared.unloadModel()
            print("✅ Model unloaded")
        } else {
            print("\n⚠️ No Foundation Models available for testing")
        }
        
        print("\n✅ All tests completed successfully!")
        
    } catch {
        print("\n❌ Test failed with error: \(error)")
    }
}

// Run the test
Task {
    await testFoundationModels()
    exit(0)
}

// Keep the script running
RunLoop.main.run()