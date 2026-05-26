// Colors.swift — Neo-Brutalist design tokens

import SwiftUI

extension Color {
    static let bgPrimary = Color(hex: "#0f0f0f")
    static let bgSecondary = Color(hex: "#1a1a1a")
    static let bgTertiary = Color(hex: "#252525")
    static let textPrimary = Color(hex: "#ffffff")
    static let textSecondary = Color(hex: "#b0b0b0")
    static let accentGreen = Color(hex: "#00ff41")
    static let accentYellow = Color(hex: "#ffd700")
    static let accentRed = Color(hex: "#ff3333")
    static let borderHeavy = Color(hex: "#ffffff")
    static let borderSubtle = Color(hex: "#404040")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
