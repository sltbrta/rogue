// RogueApp.swift — App entry point
// Neo-Brutalist iPhone app for controlling ACP-compatible CLI agents

import SwiftUI

@main
struct RogueApp: App {
    @State private var connector = GatewayConnector()
    @State private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(connector)
                .environment(sessionManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(GatewayConnector.self) private var connector
    @Environment(SessionManager.self) private var sessionManager
    @State private var selectedThreadID: String?

    var body: some View {
        NavigationSplitView {
            ThreadListView(selectedThreadID: $selectedThreadID)
        } detail: {
            if let threadID = selectedThreadID,
               let thread = sessionManager.thread(id: threadID) {
                ChatView(thread: thread)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(connector.gateways) { gateway in
                        Button(gateway.name) { connector.selectGateway(gateway.id) }
                    }
                    Divider()
                    Button("Add Gateway...") { connector.showSettings = true }
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(connector.isConnected ? Color.accentGreen : Color.accentRed)
                            .frame(width: 8, height: 8)
                        Text(connector.activeGateway?.name ?? "Disconnected")
                            .font(Font.caption)
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { connector.showSettings },
            set: { connector.showSettings = $0 }
        )) {
            GatewaySettingsView()
        }
    }
}
