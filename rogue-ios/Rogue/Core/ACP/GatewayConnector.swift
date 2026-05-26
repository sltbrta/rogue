// GatewayConnector.swift — manages Mac/cloud gateway connections

import SwiftUI
import Foundation

@Observable
final class GatewayConnector {
    var gateways: [Gateway] = []
    var activeGatewayID: String?
    var aclClient: ACPClient?
    var isConnected = false
    var showSettings = false

    var activeGateway: Gateway? {
        gateways.first { $0.id == activeGatewayID }
    }

    init() {
        loadGateways()
    }

    func selectGateway(_ id: String) {
        guard let gateway = gateways.first(where: { $0.id == id }) else { return }
        activeGatewayID = id
        Task {
            await connect(to: gateway)
        }
    }

    func connect(to gateway: Gateway) async {
        aclClient?.disconnect()
        let client = ACPClient(url: gateway.url, token: gateway.token)
        do {
            try await client.connect { _ in }
            aclClient = client
            isConnected = true
            activeGatewayID = gateway.id
        } catch {
            isConnected = false
        }
    }

    func disconnect() {
        aclClient?.disconnect()
        aclClient = nil
        isConnected = false
    }

    private func loadGateways() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "rogue_gateways"),
           let decoded = try? JSONDecoder().decode([Gateway].self, from: data) {
            gateways = decoded
        }
    }

    func saveGateway(_ gateway: Gateway) {
        if let idx = gateways.firstIndex(where: { $0.id == gateway.id }) {
            gateways[idx] = gateway
        } else {
            gateways.append(gateway)
        }
        if let data = try? JSONEncoder().encode(gateways) {
            UserDefaults.standard.set(data, forKey: "rogue_gateways")
        }
    }

    func deleteGateway(_ id: String) {
        gateways.removeAll { $0.id == id }
        if activeGatewayID == id {
            disconnect()
        }
        if let data = try? JSONEncoder().encode(gateways) {
            UserDefaults.standard.set(data, forKey: "rogue_gateways")
        }
    }
}

struct Gateway: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var url: URL
    var token: String
    var cliType: String = "opencode"
}
