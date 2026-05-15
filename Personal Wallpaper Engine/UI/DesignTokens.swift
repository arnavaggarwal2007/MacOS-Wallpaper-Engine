import SwiftUI
import AppKit

enum DesignTokens {
    enum Colors {
        static let background = Color(nsColor: .windowBackgroundColor)
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        static let cardSurface = Color(nsColor: .textBackgroundColor)
        static let cardBorder = Color.primary.opacity(0.12)
        static let cardHighlight = Color.white.opacity(0.06)
        static let primary = Color.accentColor
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }

    enum Elevation {
        static let cardRadius: CGFloat = 12
        static let cardHeroRadius: CGFloat = 18
        static let cardShadowRadius: CGFloat = 16
        static let cardShadowYOffset: CGFloat = 6
        static let heroShadowRadius: CGFloat = 22
        static let heroShadowYOffset: CGFloat = 10
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Corner {
        static let radius: CGFloat = 12
        static let heroRadius: CGFloat = 18
    }

    enum Typography {
        static let title = Font.system(size: 15, weight: .semibold)
        static let subtitle = Font.system(size: 13, weight: .medium)
        static let body = Font.system(size: 13, weight: .regular)
        static let heroTitle = Font.system(size: 24, weight: .semibold)
        static let heroSubtitle = Font.system(size: 15, weight: .regular)
    }

    enum Motion {
        static let standardDuration: Double = 0.18
        static let gentleDuration: Double = 0.12
        static let hoverShadowOpacity: Double = 0.08
        static let hoverScale: CGFloat = 1.01
    }

    enum Effects {
        static let heroBackdropOpacity: Double = 0.06
        static let cardBackdropOpacity: Double = 0.04
    }
}
