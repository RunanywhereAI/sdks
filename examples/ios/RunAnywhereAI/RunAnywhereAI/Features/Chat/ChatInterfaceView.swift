//
//  ChatInterfaceView.swift
//  RunAnywhereAI
//
//  Simplified chat interface that uses SDK analytics
//

import SwiftUI
import RunAnywhereSDK
import os.log

struct ChatInterfaceView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var conversationStore = ConversationStore.shared
    @State private var showingConversationList = false
    @State private var showingModelSelection = false
    @State private var showingAnalytics = false
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    @FocusState private var isTextFieldFocused: Bool

    private let logger = Logger(subsystem: "com.runanywhere.RunAnywhereAI", category: "ChatInterfaceView")

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chatMessagesView
                inputArea
            }
            .navigationTitle(viewModel.isModelLoaded ? (viewModel.loadedModelName ?? "Chat") : "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingConversationList = true }) {
                        Image(systemName: "list.bullet")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .sheet(isPresented: $showingConversationList) {
                ConversationListView()
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionSheet { model in
                    await handleModelSelected(model)
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                SDKAnalyticsView()
            }
            .onAppear {
                setupInitialState()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ModelLoaded"))) { _ in
                Task {
                    await viewModel.checkModelStatus()
                }
            }
            .alert("Debug Info", isPresented: $showDebugAlert) {
                Button("OK") { }
            } message: {
                Text(debugMessage)
            }
        }
    }

    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // Minimalistic model info bar at top
                if viewModel.isModelLoaded, let modelName = viewModel.loadedModelName {
                    modelInfoBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView {
                    if viewModel.messages.isEmpty && !viewModel.isGenerating {
                        // Empty state view
                        VStack(spacing: 16) {
                            Spacer()

                            Image(systemName: "message.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.6))

                            VStack(spacing: 8) {
                                Text("Start a conversation")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                if viewModel.isModelLoaded {
                                    Text("Type a message below to get started")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Select a model first, then start chatting")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LazyVStack(spacing: 16) {
                            // Add spacer at top for better scrolling
                            Spacer(minLength: 20)
                                .id("top-spacer")

                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message, isGenerating: viewModel.isGenerating)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    ))
                            }

                            if viewModel.isGenerating {
                                TypingIndicatorView()
                                    .id("typing")
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    ))
                            }

                            // Add spacer at bottom for better keyboard handling
                            Spacer(minLength: 20)
                                .id("bottom-spacer")
                        }
                        .padding()
                    }
                }
                .defaultScrollAnchor(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .contentShape(Rectangle()) // Makes entire area tappable
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                isTextFieldFocused = false
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Auto-scroll to bottom when new messages arrive
                let scrollToId: String
                if viewModel.isGenerating {
                    scrollToId = "typing"
                } else if let lastMessage = viewModel.messages.last {
                    scrollToId = lastMessage.id.uuidString
                } else {
                    scrollToId = "bottom-spacer"
                }

                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(scrollToId, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating {
                    // Scroll to bottom when generation starts
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { _, focused in
                if focused {
                    // Scroll to bottom when keyboard appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let scrollToId: String
                        if viewModel.isGenerating {
                            scrollToId = "typing"
                        } else if let lastMessage = viewModel.messages.last {
                            scrollToId = lastMessage.id.uuidString
                        } else {
                            scrollToId = "bottom-spacer"
                        }

                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(scrollToId, anchor: .bottom)
                        }
                    }
                } else {
                    // Scroll to bottom when keyboard dismisses
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let scrollToId: String
                        if viewModel.isGenerating {
                            scrollToId = "typing"
                        } else if let lastMessage = viewModel.messages.last {
                            scrollToId = lastMessage.id.uuidString
                        } else {
                            scrollToId = "bottom-spacer"
                        }

                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(scrollToId, anchor: .bottom)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // Scroll to bottom when keyboard shows
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let scrollToId: String
                    if viewModel.isGenerating {
                        scrollToId = "typing"
                    } else if let lastMessage = viewModel.messages.last {
                        scrollToId = lastMessage.id.uuidString
                    } else {
                        scrollToId = "bottom-spacer"
                    }

                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(scrollToId, anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // Scroll to bottom when keyboard hides
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let scrollToId: String
                    if viewModel.isGenerating {
                        scrollToId = "typing"
                    } else if let lastMessage = viewModel.messages.last {
                        scrollToId = lastMessage.id.uuidString
                    } else {
                        scrollToId = "bottom-spacer"
                    }

                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(scrollToId, anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MessageContentUpdated"))) { _ in
                // Scroll to bottom during streaming updates (less frequent to avoid jitter)
                if viewModel.isGenerating {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            }
        }
    }

    private var toolbarButtons: some View {
        HStack(spacing: 8) {
            // Analytics icon
            Button(action: { showingAnalytics = true }) {
                Image(systemName: "chart.bar")
                    .foregroundColor(.blue)
            }

            Button(action: { showingModelSelection = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "cube")
                    if viewModel.isModelLoaded {
                        Text("Switch")
                            .font(.caption)
                    } else {
                        Text("Select")
                            .font(.caption)
                    }
                }
            }

            Button(action: { viewModel.clearChat() }) {
                Image(systemName: "trash")
            }
            .disabled(viewModel.messages.isEmpty)
        }
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()

            // Show model selection prompt if no model is loaded
            if !viewModel.isModelLoaded {
                VStack(spacing: 8) {
                    Text("Welcome! Select and download a model to start chatting.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Select Model") {
                        showingModelSelection = true
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))

                Divider()
            }

            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(!viewModel.isModelLoaded)
                    .submitLabel(.send)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.canSend ? .accentColor : .gray)
                }
                .disabled(!viewModel.canSend)
            }
            .padding()
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.25), value: isTextFieldFocused)
        }
    }

    private func sendMessage() {
        logger.info("🎯 sendMessage() called")
        guard viewModel.canSend else {
            logger.error("❌ canSend is false, returning")
            return
        }

        logger.info("✅ Launching task to send message")
        Task {
            await viewModel.sendMessage()

            // Check for errors after a short delay
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                if let error = viewModel.error {
                    await MainActor.run {
                        debugMessage = "Error occurred: \(error.localizedDescription)"
                        showDebugAlert = true
                    }
                }
            }
        }
    }

    private func setupInitialState() {
        Task {
            await viewModel.checkModelStatus()
        }
    }

    private func handleModelSelected(_ model: ModelInfo) async {
        // The model loading is already handled in the ModelSelectionSheet
        // Just update our view model to reflect the change
        await viewModel.checkModelStatus()
    }

    // Minimalistic model info bar
    private var modelInfoBar: some View {
        HStack(spacing: 8) {
            // Framework indicator
            if let currentModel = ModelListViewModel.shared.currentModel {
                Text(currentModel.compatibleFrameworks.first?.rawValue.uppercased() ?? "AI")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                    )
            }

            // Model name (shortened)
            Text(viewModel.loadedModelName?.components(separatedBy: " ").first ?? "Model")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()

            // Key stats
            if let currentModel = ModelListViewModel.shared.currentModel {
                HStack(spacing: 12) {
                    // Model size
                    HStack(spacing: 3) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 8))
                        Text(formatModelSize(currentModel.estimatedMemory))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)

                    // Context length
                    HStack(spacing: 3) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 8))
                        Text("\(formatNumber(currentModel.contextLength))")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(Color(.systemBackground).opacity(0.95))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator))
                        .offset(y: 12)
                )
        )
    }

    // Helper functions for formatting
    private func formatModelSize(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1.0 {
            return String(format: "%.1fG", gb)
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.0fM", mb)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let k = Double(number) / 1000.0
            return String(format: "%.0fK", k)
        }
        return "\(number)"
    }
}

// Professional typing indicator with animation
struct TypingIndicatorView: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack {
            Spacer(minLength: 60)

            HStack(spacing: 12) {
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationPhase
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                )

                Text("AI is thinking...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }

            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation {
                animationPhase = 1
            }
        }
    }
}

// Simplified message bubble view 
struct MessageBubbleView: View {
    let message: Message
    let isGenerating: Bool
    @State private var isThinkingExpanded = false

    var hasThinking: Bool {
        message.thinkingContent != nil && !(message.thinkingContent?.isEmpty ?? true)
    }

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Thinking section (only for assistant messages with thinking content)
                if message.role == .assistant && hasThinking {
                    thinkingSection
                }

                // Show thinking indicator for empty messages (during streaming)
                if message.role == .assistant && message.content.isEmpty && message.thinkingContent != nil && !message.thinkingContent!.isEmpty && isGenerating {
                    thinkingProgressIndicator
                }

                // Main message content
                mainMessageBubble

                // Simple timestamp
                if !message.content.isEmpty {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    private var thinkingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Simple thinking toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isThinkingExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    // Simple icon
                    Image(systemName: "lightbulb.min")
                        .font(.caption)
                        .foregroundColor(.purple)

                    // Clean summary text
                    Text(isThinkingExpanded ? "Hide reasoning" : "Show reasoning")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .lineLimit(1)

                    Spacer()

                    // Simple expand indicator
                    Image(systemName: isThinkingExpanded ? "chevron.up" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .purple.opacity(0.2), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.purple.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Expandable thinking content with cleaner design
            if isThinkingExpanded {
                VStack(spacing: 0) {
                    ScrollView {
                        Text(message.thinkingContent ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxHeight: 150)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .slide),
                    removal: .opacity.combined(with: .slide)
                ))
            }
        }
    }

    private var thinkingProgressIndicator: some View {
        HStack(spacing: 8) {
            // Animated thinking dots instead of brain icon
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isGenerating ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isGenerating
                        )
                }
            }

            Text("Thinking...")
                .font(.caption)
                .foregroundColor(.purple.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color.purple.opacity(0.12), Color.purple.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .purple.opacity(0.2), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.purple.opacity(0.3), lineWidth: 0.5)
                )
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    @ViewBuilder
    private var mainMessageBubble: some View {
        // Only show message bubble if there's content
        if !message.content.isEmpty {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.role == .user ?
                              LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    message.role == .user ?
                                    Color.white.opacity(0.3) :
                                    Color.black.opacity(0.05),
                                    lineWidth: 0.5
                                )
                        )
                )
                .foregroundColor(message.role == .user ? .white : .primary)
                .scaleEffect(isGenerating && message.role == .assistant && message.content.count < 50 ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isGenerating)
        }
    }
}

// MARK: - SDK Analytics View Wrapper

struct SDKAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                RunAnywhereSDK.shared.createAnalyticsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
            } else {
                VStack {
                    Text("Analytics")
                        .font(.title)
                    
                    Text("Analytics view requires iOS 14.0 or later")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
