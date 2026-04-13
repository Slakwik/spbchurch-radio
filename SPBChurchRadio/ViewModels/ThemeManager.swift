import SwiftUI

/// Manages the app's color scheme preference (system / light / dark)
class ThemeManager: ObservableObject {
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "Системная"
            case .light:  return "Светлая"
            case .dark:   return "Тёмная"
            }
        }

        var iconName: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light:  return "sun.max.fill"
            case .dark:   return "moon.fill"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    @Published var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "app_theme_mode")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme_mode") ?? ThemeMode.system.rawValue
        self.mode = ThemeMode(rawValue: saved) ?? .system
    }
}
