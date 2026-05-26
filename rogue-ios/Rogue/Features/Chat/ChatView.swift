// ChatView.swift — main chat interface with streaming

import SwiftUI

struct ChatView: View {
    let thread: Thread
    @Environment(GatewayConnector.self) private var connector
    @State private var viewModel: ChatViewModel?
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(Array(vm.bubbles.enumerated()), id: \.element.id) { _, bubble in
                                ChatBubbleView(bubble: bubble)
                            }
                            if vm.isStreaming {
                                HStack { Spacer(); ProgressView().tint(.accentGreen) }
                                    .padding(.horizontal, Spacing.md)
                            }
                            if let error = vm.error {
                                ErrorBanner(message: error)
                            }
                        }
                        .padding(.vertical, Spacing.md)
                    }
                    .onChange(of: vm.bubbles.count) { _, _ in
                        if let last = vm.bubbles.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                InputBar(
                    text: $inputText,
                    isStreaming: viewModel?.isStreaming ?? false,
                    onSend: { Task { await viewModel?.sendMessage(inputText); inputText = "" } },
                    onCancel: { viewModel?.cancel() }
                )
            } else {
                ProgressView().tint(.accentGreen)
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(thread.name)
        .onAppear {
            viewModel = ChatViewModel(thread: thread, connector: connector)
        }
    }
}

struct ChatBubbleView: View {
    let bubble: ACPBubble

    var body: some View {
        switch bubble.type {
        case "user":
            UserBubble(content: bubble.content)
        case "assistant_text":
            AssistantBubble(content: bubble.content)
        case "tool_call":
            ToolCallCard(name: bubble.name ?? "tool", status: .running)
        case "tool_result":
            ToolCallCard(name: bubble.name ?? "tool", status: bubble.arguments?["is_error"] as? Bool == true ? .failed : .completed)
        case "plan":
            PlanBubble(entries: bubble.arguments?["entries"] as? [[String: Any]] ?? [])
        default:
            SystemBubble(content: bubble.content)
        }
    }
}

struct UserBubble: View {
    let content: String

    var body: some View {
        HStack {
            Spacer()
            Text(content)
                .font(Font.body)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.md)
                .background(Color.bgTertiary)
                .overlay(
                    Rectangle()
                        .stroke(Color.borderHeavy, lineWidth: 2)
                )
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct AssistantBubble: View {
    let content: String

    var body: some View {
        HStack {
            Text(content)
                .font(Font.body)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.md)
                .background(Color.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(Color.accentGreen, lineWidth: 2)
                )
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct SystemBubble: View {
    let content: String

    var body: some View {
        HStack {
            Text(content)
                .font(Font.caption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.accentRed)
            Text(message)
                .font(Font.caption)
                .foregroundStyle(Color.accentRed)
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .overlay(Rectangle().stroke(Color.accentRed, lineWidth: 2))
        .padding(.horizontal, Spacing.md)
    }
}

struct PlanBubble: View {
    let entries: [[String: Any]]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Plan")
                .font(Font.caption)
                .foregroundStyle(Color.accentYellow)
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                if let text = entry["content"] as? String {
                    Text("• \(text)")
                        .font(Font.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .overlay(Rectangle().stroke(Color.accentYellow, lineWidth: 2))
        .padding(.horizontal, Spacing.md)
    }
}

struct InputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Message", text: $text)
                .font(Font.body)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.md)
                .background(Color.bgTertiary)
                .overlay(Rectangle().stroke(Color.borderSubtle, lineWidth: 1))
                .onSubmit(onSend)

            if isStreaming {
                Button(action: onCancel) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color.accentRed)
                        .frame(width: 44, height: 44)
                }
            } else {
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.bgPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.accentGreen)
                        .overlay(Rectangle().stroke(Color.borderHeavy, lineWidth: 2))
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.borderSubtle).frame(height: 1)
        }
    }
}
