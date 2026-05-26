// EmptyStateView.swift — shown when no thread is selected

import SwiftUI

struct EmptyStateView: View {
    @Environment(GatewayConnector.self) private var connector

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Text("ROGUE")
                .font(Font.displayLarge)
                .foregroundStyle(Color.accentGreen)

            Text("Mobile CLI Agent Controller")
                .font(Font.headline)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: Spacing.md) {
                StatusRow(
                    label: "Gateway",
                    value: connector.isConnected ? connector.activeGateway?.name ?? "Connected" : "Not connected",
                    isOK: connector.isConnected
                )
                StatusRow(
                    label: "CLI",
                    value: connector.activeGateway?.cliType ?? "—",
                    isOK: connector.isConnected
                )
            }
            .padding(Spacing.lg)
            .background(Color.bgSecondary)
            .overlay(Rectangle().stroke(Color.borderHeavy, lineWidth: 2))

            Text(connector.isConnected
                 ? "Select a thread or create a new one to start"
                 : "Add a gateway connection in Settings to get started")
                .font(Font.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            if !connector.isConnected {
                Button("Add Gateway") {
                    connector.showSettings = true
                }
                .font(Font.body)
                .foregroundStyle(Color.bgPrimary)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.accentGreen)
                .overlay(Rectangle().stroke(Color.borderHeavy, lineWidth: 2))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let isOK: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(Font.caption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Circle()
                .fill(isOK ? Color.accentGreen : Color.accentRed)
                .frame(width: 8, height: 8)
            Text(value)
                .font(Font.mono)
                .foregroundStyle(isOK ? Color.accentGreen : Color.accentRed)
        }
    }
}
