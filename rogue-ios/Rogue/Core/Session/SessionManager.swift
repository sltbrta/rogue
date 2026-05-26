// SessionManager.swift — multi-thread chat session manager

import SwiftUI
import SwiftData

@Observable
final class SessionManager: @unchecked Sendable {
    var threads: [Thread] = []
    var activeSessionID: String?

    func thread(id: String) -> Thread? {
        threads.first { $0.id == id }
    }

    func createThread(name: String, cli: String, gatewayID: String) -> Thread {
        let thread = Thread(name: name, cli: cli, gatewayID: gatewayID)
        threads.append(thread)
        return thread
    }

    func deleteThread(_ id: String) {
        threads.removeAll { $0.id == id }
    }

    func addBubble(_ bubble: ACPBubble, to threadID: String) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }

        let message = ChatMessage(
            role: bubble.type == "user" ? .user : .assistant,
            content: bubble.content,
            bubbleType: bubble.type,
            toolName: bubble.name,
            toolArgs: bubble.arguments
        )

        if bubble.type == "assistant_text",
           let lastIdx = threads[idx].messages.indices.last,
           threads[idx].messages[lastIdx].role == .assistant,
           threads[idx].messages[lastIdx].bubbleType == "assistant_text" {
            threads[idx].messages[lastIdx].content += bubble.content
        } else {
            threads[idx].messages.append(message)
        }
    }
}

@Observable
final class Thread: Identifiable {
    var id = UUID().uuidString
    var name: String
    var cli: String
    var gatewayID: String
    var messages: [ChatMessage] = []
    var sessionID: String?
    var createdAt = Date()

    init(name: String, cli: String, gatewayID: String) {
        self.name = name
        self.cli = cli
        self.gatewayID = gatewayID
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: Role
    var content: String
    var bubbleType: String
    var toolName: String?
    var toolArgs: [String: String]?
    var timestamp = Date()

    enum Role { case user, assistant, system }
}
