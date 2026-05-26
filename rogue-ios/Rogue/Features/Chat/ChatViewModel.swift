// ChatViewModel.swift — observable state for chat screen

import SwiftUI

@Observable
final class ChatViewModel: @unchecked Sendable {
    var isStreaming = false
    var bubbles: [ACPBubble] = []
    var error: String?

    let thread: Thread
    private let connector: GatewayConnector

    init(thread: Thread, connector: GatewayConnector) {
        self.thread = thread
        self.connector = connector
    }

    @MainActor
    func sendMessage(_ text: String) async {
        guard let client = connector.aclClient else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isStreaming = true

        bubbles.append(ACPBubble(type: "user", content: trimmed, name: nil, arguments: nil))

        if thread.sessionID == nil || !connector.isConnected {
            do {
                let gateway = connector.activeGateway
                client.disconnect()
                try await client.connect { [weak self] bubble in
                    Task { @MainActor in self?.bubbles.append(bubble) }
                }
                thread.sessionID = try await client.initialize(
                    cli: thread.cli,
                    cwd: FileManager.default.currentDirectoryPath
                )
            } catch {
                self.error = error.localizedDescription
                isStreaming = false
                return
            }
        }

        do {
            try await client.sendPrompt(trimmed)
        } catch {
            self.error = error.localizedDescription
        }

        isStreaming = false
    }

    func cancel() {
        Task {
            try? await connector.aclClient?.cancelPrompt()
            isStreaming = false
        }
    }
}
