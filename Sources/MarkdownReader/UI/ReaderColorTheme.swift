import Foundation

/// A user-selectable color theme for both the native chrome (`AppTheme`) and
/// the rendered document (`ReaderHTMLTemplate`). `.auto` preserves the
/// original system-appearance-following behavior; the other cases force a
/// specific palette regardless of system light/dark mode.
enum ReaderColorTheme: String, CaseIterable, Identifiable, Equatable, Sendable {
    case auto
    case sepia
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .sepia: return "Sepia"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    static var current: ReaderColorTheme {
        guard let stored = UserDefaults.standard.string(forKey: ReaderPreferenceKey.colorTheme) else {
            return .auto
        }
        return ReaderColorTheme(rawValue: stored) ?? .auto
    }
}
