import SwiftUI
import AppKit

/// macOS visual effect (blur/material) for translucent chrome.
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

enum GlassChromeStyle {
    case bar
    case tabBarGroup
    case panel
    case pill(isSelected: Bool)

    var cornerRadius: CGFloat {
        switch self {
        case .bar, .tabBarGroup: return DesignTokens.Corner.radius
        case .panel: return DesignTokens.Corner.heroRadius
        case .pill: return DesignTokens.Corner.tab
        }
    }

    var material: NSVisualEffectView.Material {
        .hudWindow
    }
}

struct GlassChromeBackground: View {
    let style: GlassChromeStyle

    var body: some View {
        let radius = style.cornerRadius

        ZStack {
            if case .pill(let isSelected) = style, isSelected {
                VisualEffectView(material: style.material, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignTokens.Colors.primary.opacity(DesignTokens.Surfaces.selectedTabFillOpacity))
            } else if case .pill = style {
                VisualEffectView(material: style.material, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.black.opacity(DesignTokens.Surfaces.unselectedTabFillOpacity))
            } else if case .tabBarGroup = style {
                VisualEffectView(material: style.material, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.black.opacity(DesignTokens.Surfaces.tabBarGroupMaterialOpacity * 0.35))
            } else {
                VisualEffectView(material: style.material, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(strokeColor, lineWidth: DesignTokens.Surfaces.glassBorderWidth)
        }
        .shadow(color: .black.opacity(DesignTokens.Surfaces.glassShadowOpacity), radius: 8, y: 3)
    }

    private var strokeColor: Color {
        switch style {
        case .tabBarGroup:
            return DesignTokens.Colors.cardBorder.opacity(DesignTokens.Surfaces.glassStrokeOpacity)
        case .pill(let isSelected):
            return isSelected
                ? DesignTokens.Colors.primary.opacity(DesignTokens.Surfaces.selectedTabStrokeOpacity)
                : DesignTokens.Colors.cardBorder.opacity(DesignTokens.Surfaces.glassStrokeOpacity)
        default:
            return DesignTokens.Colors.cardBorder.opacity(DesignTokens.Surfaces.glassStrokeOpacity)
        }
    }
}

extension View {
    func glassChrome(_ style: GlassChromeStyle) -> some View {
        background {
            GlassChromeBackground(style: style)
        }
    }
}
