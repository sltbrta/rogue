// ThreadListView.swift — multi-thread switcher

import SwiftUI

struct ThreadListView: View {
    @Binding var selectedThreadID: String?
    @Environment(SessionManager.self) private var sessionManager
    @Environment(GatewayConnector.self) private var connector
    @State private var showNewThread = false

    var body: some View {
        List(selection: $selectedThreadID) {
            ForEach(sessionManager.threads) { thread in
                ThreadRow(thread: thread)
                    .tag(thread.id as String?)
            }
            .onDelete { indices in
                for idx in indices {
                    sessionManager.deleteThread(sessionManager.threads[idx].id)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Threads")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewThread = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentGreen)
                }
            }
        }
        .sheet(isPresented: $showNewThread) {
            NewThreadSheet(
                gateways: connector.gateways,
                onCreate: { name, cli, gwID in
                    let thread = sessionManager.createThread(name: name, cli: cli, gatewayID: gwID)
                    selectedThreadID = thread.id
                    showNewThread = false
                }
            )
        }
    }
}

struct ThreadRow: View {
    let thread: Thread

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(thread.name)
                .font(Font.headline)
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: Spacing.sm) {
                Text(thread.cli)
                    .font(Font.caption)
                    .foregroundStyle(Color.accentGreen)
                Text("•")
                    .font(Font.caption)
                    .foregroundStyle(Color.textSecondary)
                Text(thread.createdAt, style: .relative)
                    .font(Font.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            if let last = thread.messages.last {
                Text(last.content.prefix(60))
                    .font(Font.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct NewThreadSheet: View {
    let gateways: [Gateway]
    let onCreate: (String, String, String) -> Void
    @State private var name = ""
    @State private var cliType = "opencode"
    @State private var selectedGatewayID: String?
    @Environment(\.dismiss) private var dismiss

    let cliOptions = ["opencode", "codex", "gemini", "claude", "cursor", "qwen", "kimi"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Thread Name") {
                    TextField("e.g. Fix auth bug", text: $name)
                }

                Section("CLI Agent") {
                    Picker("Agent", selection: $cliType) {
                        ForEach(cliOptions, id: \.self) { cli in
                            Text(cli.capitalized).tag(cli)
                        }
                    }
                }

                Section("Gateway") {
                    Picker("Connection", selection: $selectedGatewayID) {
                        Text("None").tag(nil as String?)
                        ForEach(gateways) { gw in
                            Text(gw.name).tag(gw.id as String?)
                        }
                    }
                }
            }
            .navigationTitle("New Thread")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, cliType, selectedGatewayID ?? "")
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
