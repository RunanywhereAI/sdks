//
//  ChatViewModel.swift
//  RunAnywhereAI
//
//  Simplified version that uses SDK analytics
//

import Foundation
import SwiftUI
import RunAnywhereSDK
import os.log

// Local Message type for the app (simplified, no analytics)
public struct Message: Identifiable, Codable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let thinkingContent: String?
    public let timestamp: Date

    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        thinkingContent: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.thinkingContent = thinkingContent
        self.timestamp = timestamp
    }
}

enum ChatError: LocalizedError {
    case noModelLoaded

    var errorDescription: String? {
        switch self {
        case .noModelLoaded:
            return "❌ No model is loaded. Please select and load a model from the Models tab first."
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isGenerating = false
    @Published var currentInput = ""
    @Published var error: Error?
    @Published var isModelLoaded = false
    @Published var loadedModelName: String?
    @Published var useStreaming = true

    private let sdk = RunAnywhereSDK.shared
    private let conversationStore = ConversationStore.shared
    private let analyticsAdapter = AnalyticsAdapter.shared
    private var generationTask: Task<Void, Never>?
    @Published var currentConversation: Conversation?
    private var currentAnalyticsSessionId: UUID?

    private let logger = Logger(subsystem: "com.runanywhere.RunAnywhereAI", category: "ChatViewModel")

    var canSend: Bool {
        !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating && isModelLoaded
    }

    init() {
        // Always start with a new conversation for a fresh chat experience
        let conversation = conversationStore.createConversation()
        currentConversation = conversation
        messages = []

        // Add system message only if model is already loaded
        if isModelLoaded {
            addSystemMessage()
        }

        // Listen for model loaded notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelLoaded(_:)),
            name: Notification.Name("ModelLoaded"),
            object: nil
        )

        // Listen for conversation selection notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(conversationSelected(_:)),
            name: Notification.Name("ConversationSelected"),
            object: nil
        )

        // Ensure user settings are applied (safety check)
        Task {
            await ensureSettingsAreApplied()
        }
    }

    private func addSystemMessage() {
        // Only add system message if model is loaded
        guard isModelLoaded, let modelName = loadedModelName else {
            return
        }

        let content = "Model '\(modelName)' is loaded and ready to chat!"
        let systemMessage = Message(role: .system, content: content)
        messages.insert(systemMessage, at: 0)

        // Save to conversation store
        if var conversation = currentConversation {
            conversation.messages = messages
            conversationStore.updateConversation(conversation)
        }
    }

    func sendMessage() async {
        logger.info("🎯 sendMessage() called")
        logger.info("📝 canSend: \(self.canSend), isModelLoaded: \(self.isModelLoaded), loadedModelName: \(self.loadedModelName ?? "nil")")

        guard canSend else {
            logger.error("❌ canSend is false, returning")
            return
        }
        logger.info("✅ canSend is true, proceeding")

        let prompt = currentInput
        currentInput = ""
        isGenerating = true
        error = nil

        let userMessage = Message(role: .user, content: prompt)
        messages.append(userMessage)

        // Save user message to conversation
        if let conversation = currentConversation {
            conversationStore.addMessage(userMessage, to: conversation)
        }

        // Start analytics session if we don't have one
        if currentAnalyticsSessionId == nil {
            currentAnalyticsSessionId = await startAnalyticsSession()
        }

        // Create assistant message that we'll update with streaming tokens
        let assistantMessage = Message(role: .assistant, content: "")
        messages.append(assistantMessage)
        let messageIndex = messages.count - 1

        generationTask = Task {
            logger.info("🚀 Starting sendMessage task")
            do {
                logger.info("📋 Entering do block")
                logger.info("📝 Checking model status - isModelLoaded: \(self.isModelLoaded), loadedModelName: \(self.loadedModelName ?? "nil")")

                // Check if we need to reload the model in SDK
                if isModelLoaded, let _ = loadedModelName {
                    logger.info("📝 Model appears loaded, checking SDK state")
                    if let model = ModelListViewModel.shared.currentModel {
                        do {
                            _ = try await sdk.loadModel(model.id)
                            logger.info("✅ Ensured model '\(model.name)' is loaded in SDK")
                        } catch {
                            logger.error("Failed to ensure model is loaded: \(error)")
                            await MainActor.run {
                                self.isModelLoaded = false
                                self.loadedModelName = nil
                            }
                            throw ChatError.noModelLoaded
                        }
                    }
                }

                // Final check - ensure model is loaded before generating
                if !isModelLoaded {
                    logger.error("❌ Model not loaded, throwing error")
                    throw ChatError.noModelLoaded
                }

                logger.info("🎯 Starting generation with prompt: \(String(prompt.prefix(50)))..., streaming: \(self.useStreaming)")

                // Get SDK configuration for generation options
                let effectiveSettings = await sdk.getGenerationSettings()
                let options = GenerationOptions(
                    maxTokens: effectiveSettings.maxTokens,
                    temperature: Float(effectiveSettings.temperature)
                )

                logger.info("📝 Generation options created, useStreaming: \(self.useStreaming)")

                if useStreaming {
                    // Use SDK streaming with analytics
                    let stream = sdk.generateStream(prompt: prompt, options: options)
                    var fullResponse = ""
                    var isInThinkingMode = false
                    var thinkingContent = ""
                    var responseContent = ""

                    logger.info("📤 Using SDK streaming generation")

                    // Stream tokens as they arrive
                    for try await token in stream {
                        fullResponse += token

                        // Check for thinking tags
                        if fullResponse.contains("<think>") && !isInThinkingMode {
                            isInThinkingMode = true
                            logger.info("🧠 Entering thinking mode")
                        }

                        if isInThinkingMode {
                            if fullResponse.contains("</think>") {
                                // Extract thinking and response content
                                if let thinkingStart = fullResponse.range(of: "<think>"),
                                   let thinkingEnd = fullResponse.range(of: "</think>") {
                                    thinkingContent = String(fullResponse[thinkingStart.upperBound..<thinkingEnd.lowerBound])
                                    responseContent = String(fullResponse[thinkingEnd.upperBound...])
                                    isInThinkingMode = false
                                    logger.info("🧠 Exiting thinking mode - found closing tag")
                                }
                            } else {
                                // Still in thinking mode, extract current thinking content
                                if let thinkingStart = fullResponse.range(of: "<think>") {
                                    thinkingContent = String(fullResponse[thinkingStart.upperBound...])
                                }
                            }
                        } else {
                            // Not in thinking mode, show response tokens directly
                            responseContent = fullResponse.replacingOccurrences(of: "</think>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        }

                        // Update the assistant message with current content
                        await MainActor.run {
                            if messageIndex < self.messages.count {
                                let currentMessage = self.messages[messageIndex]
                                let displayContent = isInThinkingMode ? "" : responseContent
                                let updatedMessage = Message(
                                    id: currentMessage.id,
                                    role: currentMessage.role,
                                    content: displayContent,
                                    thinkingContent: thinkingContent.isEmpty ? nil : thinkingContent.trimmingCharacters(in: .whitespacesAndNewlines),
                                    timestamp: currentMessage.timestamp
                                )
                                self.messages[messageIndex] = updatedMessage

                                // Notify UI to scroll during streaming
                                NotificationCenter.default.post(name: Notification.Name("MessageContentUpdated"), object: nil)
                            }
                        }
                    }

                    logger.info("Streaming completed with response: \(fullResponse)")

                    // Handle final content processing
                    await MainActor.run {
                        if messageIndex < self.messages.count {
                            let finalContent: String
                            let finalThinking: String?

                            if let thinkingRange = fullResponse.range(of: "<think>"),
                               let thinkingEndRange = fullResponse.range(of: "</think>") {
                                finalThinking = String(fullResponse[thinkingRange.upperBound..<thinkingEndRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                                finalContent = String(fullResponse[thinkingEndRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            } else {
                                finalThinking = nil
                                finalContent = fullResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                            }

                            let updatedMessage = Message(
                                id: self.messages[messageIndex].id,
                                role: self.messages[messageIndex].role,
                                content: finalContent,
                                thinkingContent: finalThinking,
                                timestamp: self.messages[messageIndex].timestamp
                            )
                            self.messages[messageIndex] = updatedMessage
                        }
                    }

                } else {
                    // Use SDK non-streaming generation with analytics
                    let result = try await sdk.generate(prompt: prompt, options: options)
                    logger.info("Generation completed with result: \(result.text)")

                    // Update the assistant message with the complete response
                    await MainActor.run {
                        if messageIndex < self.messages.count {
                            let currentMessage = self.messages[messageIndex]
                            let updatedMessage = Message(
                                id: currentMessage.id,
                                role: currentMessage.role,
                                content: result.text,
                                thinkingContent: result.thinkingContent,
                                timestamp: currentMessage.timestamp
                            )
                            self.messages[messageIndex] = updatedMessage
                        }
                    }
                }
            } catch {
                logger.error("❌ Generation failed with error: \(error)")
                await MainActor.run {
                    self.error = error
                    // Add error message to chat
                    if messageIndex < self.messages.count {
                        let errorMessage: String
                        if error is ChatError {
                            errorMessage = error.localizedDescription
                        } else {
                            errorMessage = "❌ Generation failed: \(error.localizedDescription)"
                        }
                        let currentMessage = self.messages[messageIndex]
                        let updatedMessage = Message(
                            id: currentMessage.id,
                            role: currentMessage.role,
                            content: errorMessage,
                            timestamp: currentMessage.timestamp
                        )
                        self.messages[messageIndex] = updatedMessage
                    }
                }
            }

            await MainActor.run {
                self.isGenerating = false

                // Save final assistant message to conversation
                if messageIndex < self.messages.count,
                   let conversation = self.currentConversation {
                    var updatedConversation = conversation
                    updatedConversation.messages = self.messages
                    updatedConversation.modelName = self.loadedModelName

                    self.logger.info("💾 Saving conversation with \(self.messages.count) messages")
                    self.conversationStore.updateConversation(updatedConversation)
                }
            }
        }
    }

    // MARK: - Analytics Session Management

    private func startAnalyticsSession() async -> UUID {
        let modelId = ModelListViewModel.shared.currentModel?.id ?? "unknown"
        return await analyticsAdapter.startConversationSession(modelId: modelId)
    }

    private func endAnalyticsSession() async {
        if currentAnalyticsSessionId != nil {
            await analyticsAdapter.endCurrentSession()
            currentAnalyticsSessionId = nil
        }
    }

    // MARK: - UI Actions

    func clearChat() {
        generationTask?.cancel()
        messages.removeAll()
        currentInput = ""
        isGenerating = false
        error = nil

        // End current analytics session
        Task {
            await endAnalyticsSession()
        }

        // Create new conversation
        let conversation = conversationStore.createConversation()
        currentConversation = conversation

        // Only add system message if model is loaded
        if isModelLoaded {
            addSystemMessage()
        }
    }

    func stopGeneration() {
        generationTask?.cancel()
        isGenerating = false
    }

    func loadModel(_ modelInfo: ModelInfo) async {
        do {
            _ = try await sdk.loadModel(modelInfo.id)
            await MainActor.run {
                self.isModelLoaded = true
                self.loadedModelName = modelInfo.name
                // Update system message to reflect loaded model
                if self.messages.first?.role == .system {
                    self.messages.removeFirst()
                }
                self.addSystemMessage()
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isModelLoaded = false
                self.loadedModelName = nil
            }
        }
    }

    func checkModelStatus() async {
        let modelListViewModel = ModelListViewModel.shared

        await MainActor.run {
            if let currentModel = modelListViewModel.currentModel {
                self.isModelLoaded = true
                self.loadedModelName = currentModel.name

                // Ensure the model is actually loaded in the SDK
                Task {
                    do {
                        _ = try await sdk.loadModel(currentModel.id)
                        logger.info("Verified model '\(currentModel.name)' is loaded in SDK")
                    } catch {
                        logger.error("Failed to verify model is loaded: \(error)")
                        await MainActor.run {
                            self.isModelLoaded = false
                            self.loadedModelName = nil
                        }
                    }
                }
            } else {
                self.isModelLoaded = false
                self.loadedModelName = nil
            }

            // Update system message
            if self.messages.first?.role == .system {
                self.messages.removeFirst()
            }
            self.addSystemMessage()
        }
    }

    @objc private func modelLoaded(_ notification: Notification) {
        Task {
            if let model = notification.object as? ModelInfo {
                await MainActor.run {
                    self.isModelLoaded = true
                    self.loadedModelName = model.name
                    // Update system message to reflect loaded model
                    if self.messages.first?.role == .system {
                        self.messages.removeFirst()
                    }
                    self.addSystemMessage()
                }
            } else {
                await self.checkModelStatus()
            }
        }
    }

    @objc private func conversationSelected(_ notification: Notification) {
        if let conversation = notification.object as? Conversation {
            loadConversation(conversation)
        }
    }

    func loadConversation(_ conversation: Conversation) {
        // End current analytics session when switching conversations
        Task {
            await endAnalyticsSession()
        }

        currentConversation = conversation

        // For new conversations (empty messages), start fresh
        // For existing conversations, load the messages
        if conversation.messages.isEmpty {
            messages = []
            // Add system message if model is loaded
            if isModelLoaded {
                addSystemMessage()
            }
        } else {
            messages = conversation.messages
            logger.info("📂 Loaded conversation with \(self.messages.count) messages")
        }

        // Update model info if available
        if let modelName = conversation.modelName {
            loadedModelName = modelName
        }
    }

    func createNewConversation() {
        clearChat()
    }

    private func ensureSettingsAreApplied() async {
        // Load user settings from UserDefaults and apply to SDK if needed
        let savedTemperature = UserDefaults.standard.double(forKey: "defaultTemperature")
        let temperature = savedTemperature != 0 ? savedTemperature : 0.7

        let savedMaxTokens = UserDefaults.standard.integer(forKey: "defaultMaxTokens")
        let maxTokens = savedMaxTokens != 0 ? savedMaxTokens : 10000

        // Apply settings to SDK (this is idempotent, so safe to call multiple times)
        await sdk.setTemperature(Float(temperature))
        await sdk.setMaxTokens(maxTokens)

        logger.info("🔧 Ensured settings are applied - Temperature: \(temperature), MaxTokens: \(maxTokens)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // End analytics session on deinit
        Task {
            await endAnalyticsSession()
        }
    }
}
