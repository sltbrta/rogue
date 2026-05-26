// Typography.swift — Neo-Brutalist type system

import SwiftUI

extension Font {
    static let displayLarge = Font.custom("SpaceGrotesk-Bold", size: 32, relativeTo: .largeTitle)
    static let headline = Font.custom("SpaceGrotesk-Bold", size: 20, relativeTo: .title3)
    static let body = Font.custom("SpaceGrotesk-Regular", size: 16, relativeTo: .body)
    static let mono = Font.custom("JetBrainsMono-Regular", size: 14, relativeTo: .caption)
    static let caption = Font.custom("SpaceGrotesk-Medium", size: 12, relativeTo: .caption2)
}

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}
