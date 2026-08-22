import AppKit
import SwiftUI

/// Native-chrome palette. Every token is defined once per theme family so the
/// sidebar, toolbar, and library surfaces stay in step with the rendered
/// document palette in `ReaderHTMLTemplate`.
enum AppTheme {
    // Fresh (default) — cool near-white with an indigo accent.
    private static let accentFresh: UInt32 = 0x5B54E8
    private static let accentFreshDark: UInt32 = 0xA7A2FF
    private static let inkFresh: UInt32 = 0x15171C
    private static let inkFreshDark: UInt32 = 0xE9EBF1

    // Sepia — the warm paper look, kept as a deliberate reading option.
    private static let accentSepia: UInt32 = 0x98622F
    private static let inkSepia: UInt32 = 0x2A2118

    static var tint: Color { token(\.tint) }
    static var windowBackground: Color { token(\.windowBackground) }
    static var detailBackground: Color { token(\.detailBackground) }
    static var sidebarBackground: Color { token(\.sidebarBackground) }
    static var surface: Color { token(\.surface) }
    static var elevatedSurface: Color { token(\.elevatedSurface) }
    static var chromeSurface: Color { token(\.chromeSurface) }
    static var iconTile: Color { token(\.iconTile) }
    static var rowHover: Color { token(\.rowHover) }
    static var primaryText: Color { token(\.primaryText) }
    static var secondaryText: Color { token(\.secondaryText) }
    static var tertiaryText: Color { token(\.tertiaryText) }
    static var warning: Color { token(\.warning) }
    static var controlProminentFill: Color { token(\.controlProminentFill) }
    static var controlProminentHoverFill: Color { token(\.controlProminentHoverFill) }
    static var controlProminentText: Color { token(\.controlProminentText) }

    static var border: Color { ink(alpha: 0.16) }
    static var softBorder: Color { ink(alpha: 0.085) }
    static var divider: Color { ink(alpha: 0.10) }
    static var controlSubtleFill: Color { ink(alpha: 0.06) }
    static var controlBorder: Color { ink(alpha: 0.14) }

    static var subtleAccentFill: Color { accent(alpha: 0.12) }
    static var subtleAccentBorder: Color { accent(alpha: 0.30) }
    static var controlHoverFill: Color { accent(alpha: 0.11) }
    static var controlHoverBorder: Color { accent(alpha: 0.26) }
    static var controlFill: Color { token(\.controlFill) }

    // MARK: - Palettes

    private struct Palette {
        var tint: Color
        var windowBackground: Color
        var detailBackground: Color
        var sidebarBackground: Color
        var surface: Color
        var elevatedSurface: Color
        var chromeSurface: Color
        var iconTile: Color
        var rowHover: Color
        var primaryText: Color
        var secondaryText: Color
        var tertiaryText: Color
        var warning: Color
        var controlFill: Color
        var controlProminentFill: Color
        var controlProminentHoverFill: Color
        var controlProminentText: Color
    }

    private static let freshLight = Palette(
        tint: hex(accentFresh),
        windowBackground: hex(0xF7F8FB),
        detailBackground: hex(0xFDFDFE),
        sidebarBackground: hex(0xF4F5F8),
        surface: hex(0xFFFFFF),
        elevatedSurface: hex(0xFFFFFF),
        chromeSurface: hex(0xF9FAFC),
        iconTile: hex(0xEDEEF4),
        rowHover: hex(0xEBECF2),
        primaryText: hex(0x15171C),
        secondaryText: hex(0x5F636E),
        tertiaryText: hex(0x878B96),
        warning: hex(0xC2410C),
        controlFill: hex(0xFFFFFF),
        controlProminentFill: hex(accentFresh),
        controlProminentHoverFill: hex(0x4B44D6),
        controlProminentText: hex(0xFFFFFF)
    )

    private static let freshDark = Palette(
        tint: hex(accentFreshDark),
        windowBackground: hex(0x0D0E12),
        detailBackground: hex(0x101116),
        sidebarBackground: hex(0x0B0C10),
        surface: hex(0x191B22),
        elevatedSurface: hex(0x1E2029),
        chromeSurface: hex(0x16181F),
        iconTile: hex(0x232631),
        rowHover: hex(0x232631),
        primaryText: hex(0xE9EBF1),
        secondaryText: hex(0x9CA1AE),
        tertiaryText: hex(0x7A7F8C),
        warning: hex(0xE9975B),
        controlFill: hex(0x1E2029),
        controlProminentFill: hex(accentFreshDark),
        controlProminentHoverFill: hex(0xB8B3FF),
        controlProminentText: hex(0x14131F)
    )

    private static let sepia = Palette(
        tint: hex(accentSepia),
        windowBackground: hex(0xF1EADC),
        detailBackground: hex(0xF7F1E5),
        sidebarBackground: hex(0xEBE2D1),
        surface: hex(0xFBF6ED),
        elevatedSurface: hex(0xFDF9F1),
        chromeSurface: hex(0xF5EFE3),
        iconTile: hex(0xEBDFCC),
        rowHover: hex(0xE9DCC7),
        primaryText: hex(0x2A2118),
        secondaryText: hex(0x6B5C4A),
        tertiaryText: hex(0x8B7B66),
        warning: hex(0xA85B30),
        controlFill: hex(0xFFFCF6),
        controlProminentFill: hex(accentSepia),
        controlProminentHoverFill: hex(0x82521F),
        controlProminentText: hex(0xFFFAF1)
    )

    // MARK: - Resolution

    private static func token(_ keyPath: KeyPath<Palette, Color>) -> Color {
        switch ReaderColorTheme.current {
        case .sepia:
            return sepia[keyPath: keyPath]
        case .light:
            return freshLight[keyPath: keyPath]
        case .dark:
            return freshDark[keyPath: keyPath]
        case .auto:
            return dynamic(
                light: freshLight[keyPath: keyPath],
                dark: freshDark[keyPath: keyPath]
            )
        }
    }

    /// Ink-derived tokens (borders, dividers, subtle fills) scale a single
    /// foreground color by alpha so they stay legible on every background.
    private static func ink(alpha: CGFloat) -> Color {
        switch ReaderColorTheme.current {
        case .sepia:
            return Color(nsColor(inkSepia, alpha: alpha))
        case .light:
            return Color(nsColor(inkFresh, alpha: alpha))
        case .dark:
            return Color(nsColor(inkFreshDark, alpha: alpha * 1.15))
        case .auto:
            return dynamic(
                light: Color(nsColor(inkFresh, alpha: alpha)),
                dark: Color(nsColor(inkFreshDark, alpha: alpha * 1.15))
            )
        }
    }

    private static func accent(alpha: CGFloat) -> Color {
        switch ReaderColorTheme.current {
        case .sepia:
            return Color(nsColor(accentSepia, alpha: alpha))
        case .light:
            return Color(nsColor(accentFresh, alpha: alpha))
        case .dark:
            return Color(nsColor(accentFreshDark, alpha: alpha))
        case .auto:
            return dynamic(
                light: Color(nsColor(accentFresh, alpha: alpha)),
                dark: Color(nsColor(accentFreshDark, alpha: alpha))
            )
        }
    }

    private static func dynamic(light: Color, dark: Color) -> Color {
        Color(
            nsColor: NSColor(
                name: nil,
                dynamicProvider: { appearance in
                    let match = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
                    let isDark = match == .darkAqua || match == .vibrantDark
                    return NSColor(isDark ? dark : light)
                }
            )
        )
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(nsColor(value))
    }

    private static func nsColor(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
