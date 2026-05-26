// SlashCommandPalette.swift — slash command overlay

import SwiftUI

struct SlashCommandPalette: View {
    @Binding var inputText: String
    @Binding var showPalette: Bool
    let onSubmit: (String) -> Void

    let commands: [SlashCommand] = [
        SlashCommand(id: "/file", description: "Attach a file", icon: "doc"),
        SlashCommand(id: "/image", description: "Attach an image", icon: "photo"),
        SlashCommand(id: "/clear", description: "Clear thread", icon: "trash"),
        SlashCommand(id: "/switch", description: "Switch CLI agent", icon: "arrow.triangle.swap"),
        SlashCommand(id: "/threads", description: "Open thread list", icon: "list.bullet"),
        SlashCommand(id: "/status", description: "Gateway status", icon: "antenna.radiowaves.left.and.right"),
        SlashCommand(id: "/retry", description: "Retry last message", icon: "arrow.counterclockwise"),
        SlashCommand(id: "/stop", description: "Cancel current task", icon: "stop"),
        SlashCommand(id: "/export", description: "Export thread as markdown", icon: "square.and.arrow.up"),
    ]

    var filtered: [SlashCommand] {
        if inputText.isEmpty { return commands }
        let prefix = inputText.lowercased()
        return commands.filter { $0.id.lowercased().contains(prefix) || $0.description.lowercased().contains(prefix) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filtered) { cmd in
                Button {
                    inputText = cmd.id + " "
                    showPalette = false
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: cmd.icon)
                            .frame(width: 24)
                            .foregroundStyle(Color.accentGreen)
                        VStack(alignment: .leading) {
                            Text(cmd.id)
                                .font(Font.mono)
                                .foregroundStyle(Color.textPrimary)
                            Text(cmd.description)
                                .font(Font.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.bgSecondary)
        .overlay(Rectangle().stroke(Color.accentGreen, lineWidth: 2))
    }
}

struct SlashCommand: Identifiable {
    let id: String
    let description: String
    let icon: String
}
