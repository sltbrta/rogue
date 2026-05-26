// ACPClient.swift — JSON-RPC 2.0 WebSocket client for ACP

import Foundation

@Observable
final class ACPClient {
    private var task: URLSessionWebSocketTask?
    private var requestID = AtomicInt(0)
    private var onUpdate: ((ACPBubble) -> Void)?

    let url: URL
    let token: String
    var isConnected = false

    init(url: URL, token: String) {
        self.url = url
        self.token = token
    }

    func connect(onUpdate: @escaping (ACPBubble) -> Void) async throws {
        self.onUpdate = onUpdate
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: request)
        task?.resume()
        isConnected = true
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    func initialize(cli: String, cwd: String) async throws -> String {
        let response = try await send(method: "initialize", params: [
            "token": token,
            "cli": cli,
            "cwd": cwd,
        ])
        guard let result = response?["result"] as? [String: Any],
              let sessionID = result["session_id"] as? String else {
            throw ACPError.initializationFailed
        }
        receiveLoop()
        return sessionID
    }

    func sendPrompt(_ text: String) async throws {
        _ = try await send(method: "session/prompt", params: ["prompt": text])
    }

    func cancel() async throws {
        _ = try await send(method: "session/cancel", params: [:])
    }

    func close() async throws {
        _ = try await send(method: "session/close", params: [:])
        disconnect()
    }

    private func send(
        method: String,
        params: [String: Any]
    ) async throws -> [String: Any]? {
        let id = requestID.next()
        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        ]
        let data = try JSONSerialization.data(withJSONObject: message)
        try await task?.send(.data(data))
        let raw = try await receive()
        guard let dict = raw as? [String: Any],
              (dict["id"] as? Int) == id,
              dict["error"] == nil else {
            if let error = (raw as? [String: Any])?["error"] as? [String: Any] {
                throw ACPError.serverError(String(describing: error["message"]))
            }
            throw ACPError.protocolError
        }
        return dict
    }

    private func receiveLoop() {
        Task {
            guard let task else { return }
            do {
                while isConnected {
                    let raw = try await receive()
                    if let dict = raw as? [String: Any],
                       dict["method"] as? String == "session/update",
                       let params = dict["params"] as? [String: Any] {
                        let bubble = ACPBubble(
                            type: params["type"] as? String ?? "unknown",
                            content: params["content"] as? String ?? "",
                            name: params["name"] as? String,
                            arguments: params["arguments"] as? [String: Any]
                        )
                        await MainActor.run { onUpdate?(bubble) }
                    }
                }
            } catch {
                await MainActor.run { isConnected = false }
            }
        }
    }

    private func receive() async throws -> Any {
        let message = try await task?.receive()
        switch message {
        case .data(let data):
            return try JSONSerialization.jsonObject(with: data)
        case .string(let text):
            return try JSONSerialization.jsonObject(
                with: text.data(using: .utf8) ?? Data()
            )
        case .none, .some(.data):
            throw ACPError.connectionLost
        @unknown default:
            throw ACPError.connectionLost
        }
    }
}

struct ACPBubble: Identifiable {
    let id = UUID()
    let type: String
    let content: String
    let name: String?
    let arguments: [String: Any]?
}

enum ACPError: Error {
    case initializationFailed
    case protocolError
    case serverError(String)
    case connectionLost
}

final class AtomicInt: @unchecked Sendable {
    private var value: Int
    private let lock = NSLock()
    init(_ value: Int = 0) { self.value = value }
    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        value += 1; return value
    }
}
