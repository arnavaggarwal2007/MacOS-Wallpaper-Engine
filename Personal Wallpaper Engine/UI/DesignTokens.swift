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
        static let tab: CGFloat = 8
        static let thumbnail: CGFloat = 10
    }

    enum Surfaces {
        static let scrollBackdropOpacity: Double = 0.65
        static let selectedTabFillOpacity: Double = 0.15
        static let selectedTabStrokeOpacity: Double = 0.28
        static let thumbnailShadowOpacity: Double = 0.18
        static let glassStrokeOpacity: Double = 0.12
        static let glassBorderWidth: CGFloat = 1
        static let glassShadowOpacity: Double = 0.06
        /// Translucent backing for the floating tab pill group (readability on bright heroes).
        static let tabBarGroupMaterialOpacity: Double = 0.88
        static let unselectedTabFillOpacity: Double = 0.42
        static let managementScrimOpacity: Double = 0.50
        static let managementBlurOpacity: Double = 0.72
        /// Space reserved for floating tab pills in TabbedMainView overlay.
        static let mainTabBarReservedHeight: CGFloat = 52
        static let homeUtilityBarReservedHeight: CGFloat = 108
        static let homeScrollPeekHeight: CGFloat = 44
        /// Approximate height of the display carousel panel (for below-fold math).
        static let homeDisplaysPanelHeight: CGFloat = 248
        /// Scroll offset (pt) before the display panel is revealed.
        static let homeDisplaysRevealThreshold: CGFloat = 48
        /// Scroll offset (pt) below which the display panel is hidden again.
        static let homeDisplaysHideThreshold: CGFloat = 20
        static let thumbnailLandscapeAspectWidth: CGFloat = 16
        static let thumbnailLandscapeAspectHeight: CGFloat = 9
        static let thumbnailLandscapeWidth: CGFloat = 96
        static let thumbnailLandscapeSummaryWidth: CGFloat = 160
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

        static func selectionAnimation(reduceMotion: Bool) -> Animation {
            reduceMotion ? .linear(duration: 0) : .easeInOut(duration: standardDuration)
        }

        static func hoverAnimation(reduceMotion: Bool) -> Animation {
            reduceMotion ? .linear(duration: 0) : .easeInOut(duration: standardDuration)
        }
    }

    enum Effects {
        static let heroBackdropOpacity: Double = 0.06
        static let cardBackdropOpacity: Double = 0.04
    }
}
