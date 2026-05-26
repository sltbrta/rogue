// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RogueCore", targets: ["RogueCore"]),
        .library(name: "RogueUI", targets: ["RogueUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/exyte/Chat", from: "2.0.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "RogueCore",
            dependencies: [],
            path: "Rogue/Core",
            sources: [
                "ACP/ACPClient.swift",
                "ACP/GatewayConnector.swift",
                "Session/SessionManager.swift",
                "Design/Colors.swift",
                "Design/Typography.swift",
            ]
        ),
        .target(
            name: "RogueUI",
            dependencies: ["RogueCore"],
            path: "Rogue",
            sources: [
                "App/RogueApp.swift",
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
