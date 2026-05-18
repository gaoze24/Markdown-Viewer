import AppKit
import SwiftUI

enum AppTheme {
    static let tint = dynamicColor(light: 0x8A6B48, dark: 0xC9A57B)
    static let windowBackground = dynamicColor(light: 0xF5F0E7, dark: 0x17120F)
    static let detailBackground = dynamicColor(light: 0xF7F2E8, dark: 0x1A1511)
    static let sidebarBackground = dynamicColor(light: 0xEEE5D9, dark: 0x15110E)
    static let surface = dynamicColor(light: 0xF4EDE1, dark: 0x241D18)
    static let elevatedSurface = dynamicColor(light: 0xF8F2E7, dark: 0x28211B)
    static let chromeSurface = dynamicColor(light: 0xF2EADD, dark: 0x221B16)
    static let iconTile = dynamicColor(light: 0xEBE1D2, dark: 0x2A211A)
    static let rowHover = dynamicColor(light: 0xECE1D2, dark: 0x2C241D)
    static let primaryText = dynamicColor(light: 0x2E261F, dark: 0xEEE3D6)
    static let secondaryText = dynamicColor(light: 0x776B5F, dark: 0xB6A595)
    static let tertiaryText = dynamicColor(light: 0x97887A, dark: 0x8F8073)
    static let border = dynamicColor(light: 0x76624C, dark: 0xD8C4AB, lightAlpha: 0.16, darkAlpha: 0.16)
    static let softBorder = dynamicColor(light: 0x76624C, dark: 0xD8C4AB, lightAlpha: 0.09, darkAlpha: 0.10)
    static let divider = dynamicColor(light: 0x76624C, dark: 0xD8C4AB, lightAlpha: 0.10, darkAlpha: 0.11)
    static let warning = dynamicColor(light: 0xB16F49, dark: 0xD79267)
    static let subtleAccentFill = dynamicColor(light: 0x8A6B48, dark: 0xC9A57B, lightAlpha: 0.08, darkAlpha: 0.12)
    static let subtleAccentBorder = dynamicColor(light: 0x8A6B48, dark: 0xC9A57B, lightAlpha: 0.22, darkAlpha: 0.24)
    static let controlHoverFill = dynamicColor(light: 0x8A6B48, dark: 0xC9A57B, lightAlpha: 0.10, darkAlpha: 0.15)
    static let controlHoverBorder = dynamicColor(light: 0x8A6B48, dark: 0xC9A57B, lightAlpha: 0.18, darkAlpha: 0.20)
    static let controlSubtleFill = dynamicColor(light: 0x76624C, dark: 0xD8C4AB, lightAlpha: 0.05, darkAlpha: 0.08)
    static let controlFill = dynamicColor(light: 0xFFF8EF, dark: 0x2E261F, lightAlpha: 0.92, darkAlpha: 0.96)
    static let controlBorder = dynamicColor(light: 0x76624C, dark: 0xD8C4AB, lightAlpha: 0.24, darkAlpha: 0.22)
    static let controlProminentFill = dynamicColor(light: 0x7A5D3D, dark: 0xD1AA7A)
    static let controlProminentHoverFill = dynamicColor(light: 0x6B5135, dark: 0xE0B98A)
    static let controlProminentText = dynamicColor(light: 0xFFF8EF, dark: 0x1F160F)

    static func outlineAccent(for level: Int) -> Color {
        switch level {
        case 1:
            return dynamicColor(light: 0x8E6E4B, dark: 0xC7A37A)
        case 2:
            return dynamicColor(light: 0xA28663, dark: 0xB79A74)
        default:
            return dynamicColor(light: 0xC4B39D, dark: 0x736555)
        }
    }

    static func progressTint(for progress: Double) -> Color {
        switch progress {
        case ..<0.33:
            return dynamicColor(light: 0xC39B6B, dark: 0xD1AE83)
        case ..<0.8:
            return dynamicColor(light: 0x9A7A58, dark: 0xBC9870)
        default:
            return dynamicColor(light: 0x7A6147, dark: 0xD2B188)
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
