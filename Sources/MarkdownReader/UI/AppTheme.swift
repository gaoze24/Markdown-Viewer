import AppKit
import SwiftUI

enum AppTheme {
    private static let accentLight: UInt32 = 0x7C5836
    private static let accentDark: UInt32 = 0xD6B084
    private static let inkLight: UInt32 = 0x5A4126
    private static let inkDark: UInt32 = 0xE9D7BD

    static let tint = dynamicColor(light: accentLight, dark: accentDark)
    static let windowBackground = dynamicColor(light: 0xF1EADC, dark: 0x140F0B)
    static let detailBackground = dynamicColor(light: 0xF4EEE2, dark: 0x171210)
    static let sidebarBackground = dynamicColor(light: 0xE8DCCB, dark: 0x110D0A)
    static let surface = dynamicColor(light: 0xFAF4EA, dark: 0x271F19)
    static let elevatedSurface = dynamicColor(light: 0xFDF9F1, dark: 0x2D251E)
    static let chromeSurface = dynamicColor(light: 0xF7F0E4, dark: 0x251E18)
    static let iconTile = dynamicColor(light: 0xEDE1CF, dark: 0x312820)
    static let rowHover = dynamicColor(light: 0xEADBC6, dark: 0x342A21)
    static let primaryText = dynamicColor(light: 0x201810, dark: 0xF6EDE1)
    static let secondaryText = dynamicColor(light: 0x5E5142, dark: 0xC9B9A6)
    static let tertiaryText = dynamicColor(light: 0x7F6F5C, dark: 0xA1917E)
    static let border = dynamicColor(light: inkLight, dark: inkDark, lightAlpha: 0.24, darkAlpha: 0.22)
    static let softBorder = dynamicColor(light: inkLight, dark: inkDark, lightAlpha: 0.14, darkAlpha: 0.15)
    static let divider = dynamicColor(light: inkLight, dark: inkDark, lightAlpha: 0.15, darkAlpha: 0.16)
    static let warning = dynamicColor(light: 0xA85B30, dark: 0xE49A6A)
    static let subtleAccentFill = dynamicColor(light: accentLight, dark: accentDark, lightAlpha: 0.11, darkAlpha: 0.17)
    static let subtleAccentBorder = dynamicColor(light: accentLight, dark: accentDark, lightAlpha: 0.32, darkAlpha: 0.34)
    static let controlHoverFill = dynamicColor(light: accentLight, dark: accentDark, lightAlpha: 0.13, darkAlpha: 0.19)
    static let controlHoverBorder = dynamicColor(light: accentLight, dark: accentDark, lightAlpha: 0.26, darkAlpha: 0.28)
    static let controlSubtleFill = dynamicColor(light: inkLight, dark: inkDark, lightAlpha: 0.08, darkAlpha: 0.11)
    static let controlFill = dynamicColor(light: 0xFFFCF6, dark: 0x322A22, lightAlpha: 0.96, darkAlpha: 0.98)
    static let controlBorder = dynamicColor(light: inkLight, dark: inkDark, lightAlpha: 0.30, darkAlpha: 0.26)
    static let controlProminentFill = dynamicColor(light: 0x6E4E2E, dark: 0xDBB484)
    static let controlProminentHoverFill = dynamicColor(light: 0x5B3E22, dark: 0xE9C292)
    static let controlProminentText = dynamicColor(light: 0xFFFAF1, dark: 0x1A1208)

    static func outlineAccent(for level: Int) -> Color {
        switch level {
        case 1:
            return dynamicColor(light: 0x805B36, dark: 0xD2AC7E)
        case 2:
            return dynamicColor(light: 0x977A55, dark: 0xBE9F73)
        default:
            return dynamicColor(light: 0xB7A085, dark: 0x7C6C59)
        }
    }

    static func progressTint(for progress: Double) -> Color {
        switch progress {
        case ..<0.33:
            return dynamicColor(light: 0xBE9159, dark: 0xD8B485)
        case ..<0.8:
            return dynamicColor(light: 0x8E6C49, dark: 0xC59B6E)
        default:
            return dynamicColor(light: 0x6C5236, dark: 0xDBB98C)
        }
    }

    private static func dynamicColor(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(
            nsColor: NSColor(
                name: nil,
                dynamicProvider: { appearance in
                    let match = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
                    let isDark = match == .darkAqua || match == .vibrantDark
                    return color(
                        hex: isDark ? dark : light,
                        alpha: isDark ? darkAlpha : lightAlpha
                    )
                }
            )
        )
    }

    private static func color(hex: UInt32, alpha: CGFloat = 1) -> NSColor {
        NSColor(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
