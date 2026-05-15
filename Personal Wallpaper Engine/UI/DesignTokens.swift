import SwiftUI
import AppKit

enum DesignTokens {
    enum Colors {
        static let background = Color(nsColor: .windowBackgroundColor)
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        static let primary = Color.accentColor
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Corner {
        static let radius: CGFloat = 10
        static let heroRadius: CGFloat = 14
    }

    enum Typography {
        static let title = Font.headline
        static let subtitle = Font.subheadline
        static let body = Font.body
        static let heroTitle = Font.system(size: 20, weight: .semibold)
        static let heroSubtitle = Font.system(size: 14, weight: .regular)
    }

    enum Motion {
        static let standardDuration: Double = 0.18
        static let gentleDuration: Double = 0.12
        static let hoverShadowOpacity: Double = 0.08
        static let hoverScale: CGFloat = 1.01
    }
}
