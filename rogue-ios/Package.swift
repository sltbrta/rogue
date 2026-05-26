// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RogueLib", targets: ["RogueLib"]),
    ],
    targets: [
        .target(
            name: "RogueLib",
            path: "Rogue",
            sources: [
                "App/RogueApp.swift",
                "Core/ACP/ACPClient.swift",
                "Core/ACP/GatewayConnector.swift",
                "Core/Session/SessionManager.swift",
                "Core/Design/Colors.swift",
                "Core/Design/Typography.swift",
                "Features/Chat/ChatView.swift",
                "Features/Chat/ChatViewModel.swift",
                "Features/Chat/ToolCallCard.swift",
                "Features/Chat/EmptyStateView.swift",
                "Features/Threads/ThreadListView.swift",
                "Features/Commands/SlashCommandPalette.swift",
                "Features/Settings/GatewaySettingsView.swift",
            ]
        ),
    ]
)
