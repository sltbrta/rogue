// ToolCallCard.swift — tool execution visualization

import SwiftUI

enum ToolStatus { case running, completed, failed }

struct ToolCallCard: View {
    let name: String
    let status: ToolStatus
    @State private var isExpanded = false

    var statusColor: Color {
        switch status {
        case .running: return Color.accentYellow
        case .completed: return Color.accentGreen
        case .failed: return Color.accentRed
        }
    }

    var statusIcon: String {
        switch status {
        case .running: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isExpanded.toggle() } } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                    Text(name)
                        .font(Font.mono)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .overlay(Rectangle().stroke(statusColor, lineWidth: 2))
        .padding(.horizontal, Spacing.md)
    }
}

struct ApprovalGate: View {
    let toolName: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.accentYellow)
                Text("Approve \(toolName)?")
                    .font(Font.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            HStack(spacing: Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    Button(option) { onSelect(option) }
                        .font(Font.caption)
                        .foregroundStyle(Color.bgPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.accentGreen)
                        .overlay(Rectangle().stroke(Color.borderHeavy, lineWidth: 2))
                }
                Button("Deny") { onSelect("deny") }
                    .font(Font.caption)
                    .foregroundStyle(Color.accentRed)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.bgTertiary)
                    .overlay(Rectangle().stroke(Color.accentRed, lineWidth: 2))
            }
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .overlay(Rectangle().stroke(Color.accentYellow, lineWidth: 2))
        .padding(.horizontal, Spacing.md)
    }
}
