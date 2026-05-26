// GatewaySettingsView.swift — add/edit gateway connections

import SwiftUI

struct GatewaySettingsView: View {
    @Environment(GatewayConnector.self) private var connector
    @State private var name = ""
    @State private var url = "ws://localhost:8787/ws"
    @State private var token = ""
    @State private var cliType = "opencode"
    @Environment(\.dismiss) private var dismiss

    let cliOptions = ["opencode", "codex", "gemini", "claude", "cursor", "qwen", "kimi"]

    var body: some View {
        NavigationStack {
            List {
                Section("Your Gateways") {
                    ForEach(connector.gateways) { gateway in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(gateway.name)
                                .font(Font.headline)
                                .foregroundStyle(Color.textPrimary)
                            Text(gateway.url.absoluteString)
                                .font(Font.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text(gateway.cliType)
                                .font(Font.caption)
                                .foregroundStyle(Color.accentGreen)
                        }
                    }
                    .onDelete { indices in
                        for idx in indices {
                            connector.deleteGateway(connector.gateways[idx].id)
                        }
                    }
                }

                Section("Add Gateway") {
                    TextField("Name (e.g. MacBook Pro)", text: $name)
                    TextField("URL (ws://...)", text: $url)
                        .font(Font.mono)
                        .autocapitalization(.none)
                    TextField("Auth Token", text: $token)
                        .font(Font.mono)
                        .autocapitalization(.none)
                    Picker("CLI Type", selection: $cliType) {
                        ForEach(cliOptions, id: \.self) { cli in
                            Text(cli.capitalized)
                        }
                    }
                    Button("Add") {
                        guard let wsURL = URL(string: url), !name.isEmpty else { return }
                        let gateway = Gateway(
                            name: name,
                            url: wsURL,
                            token: token,
                            cliType: cliType
                        )
                        connector.saveGateway(gateway)
                        connector.selectGateway(gateway.id)
                        dismiss()
                    }
                    .foregroundStyle(Color.accentGreen)
                    .disabled(name.isEmpty || URL(string: url) == nil)
                }
            }
            .navigationTitle("Gateways")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
