// ACPClient.swift — JSON-RPC 2.0 WebSocket client for ACP
// Swift 6 strict concurrency safe via @unchecked Sendable

import Foundation

@Observable
final class ACPClient: @unchecked Sendable {
    private nonisolated(unsafe) var wsTask: URLSessionWebSocketTask?
    private let requestID = AtomicInt(0)
    private nonisolated(unsafe) var onUpdate: (@Sendable (ACPBubble) -> Void)?
    private nonisolated(unsafe) var receiveTask: Task<Void, Never>?

    let url: URL
    let token: String
    var isConnected = false

    init(url: URL, token: String) {
        self.url = url
        self.token = token
    }

    func connect(onUpdate: @escaping @Sendable (ACPBubble) -> Void) async throws {
        self.onUpdate = onUpdate
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let session = URLSession(configuration: .default)
        wsTask = session.webSocketTask(with: request)
        wsTask?.resume()
        isConnected = true
        startReceiveLoop()
    }

    func disconnect() {
        receiveTask?.cancel()
        wsTask?.cancel(with: .normalClosure, reason: nil)
        wsTask = nil
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
        return sessionID
    }

    func sendPrompt(_ text: String) async throws {
        _ = try await send(method: "session/prompt", params: ["prompt": text])
    }

    func cancelPrompt() async throws {
        _ = try await send(method: "session/cancel", params: [:])
    }

    func closeSession() async throws {
        _ = try await send(method: "session/close", params: [:])
        disconnect()
    }

    private func send(method: String, params: [String: Any]) async throws -> [String: Any]? {
        let id = requestID.next()
        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        ]
        let data = try JSONSerialization.data(withJSONObject: message)
        try await wsTask?.send(.data(data))
        return try await receiveResponse(expectingID: id)
    }

    private func startReceiveLoop() {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let raw = try? await self.receiveAny() else { continue }
                guard let dict = raw as? [String: Any],
                      dict["method"] as? String == "session/update",
                      let params = dict["params"] as? [String: Any] else { continue }
                let bubble = ACPBubble(
                    type: params["type"] as? String ?? "unknown",
                    content: params["content"] as? String ?? "",
                    name: params["name"] as? String,
                    arguments: (params["arguments"] as? [String: Any])?.compactMapValues { String(describing: $0) }
                )
                self.onUpdate?(bubble)
            }
        }
    }

    private func receiveAny() async throws -> Any {
        guard let task = wsTask else { throw ACPError.connectionLost }
        let message = try await task.receive()
        switch message {
        case .data(let data):
            return try JSONSerialization.jsonObject(with: data)
        case .string(let text):
            return try JSONSerialization.jsonObject(with: text.data(using: .utf8) ?? Data())
        @unknown default:
            throw ACPError.connectionLost
        }
    }

    private func receiveResponse(expectingID: Int) async throws -> [String: Any]? {
        let raw = try await receiveAny()
        guard let dict = raw as? [String: Any],
              (dict["id"] as? Int) == expectingID,
              dict["error"] == nil else {
            if let error = (raw as? [String: Any])?["error"] as? [String: Any] {
                throw ACPError.serverError(String(describing: error["message"]))
            }
            throw ACPError.protocolError
        }
        return dict
    }
}

struct ACPBubble: Identifiable, Sendable {
    let id = UUID()
    let type: String
    let content: String
    let name: String?
    let arguments: [String: String]?

    static func == (lhs: ACPBubble, rhs: ACPBubble) -> Bool { lhs.id == rhs.id }
}

enum ACPError: Error, Sendable {
    case initializationFailed
    case protocolError
    case serverError(String)
    case connectionLost
}

final class AtomicInt: @unchecked Sendable {
    private nonisolated(unsafe) var value: Int
    private let lock = NSLock()
    init(_ value: Int = 0) { self.value = value }
    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        value += 1; return value
    }
}
