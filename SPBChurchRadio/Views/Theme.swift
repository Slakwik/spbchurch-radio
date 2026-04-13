import SwiftUI

// MARK: - Adaptive Color Palette

/// Neumorphic color palette with full Dark Mode support
enum AppColors {
    // MARK: - Light Mode
    private static let _lightBackground = Color(red: 0.941, green: 0.941, blue: 0.953)      // #F0F0F3
    private static let _lightSurface = Color(red: 0.949, green: 0.949, blue: 0.961)         // #F2F2F5
    private static let _lightShadowDark = Color(red: 0.659, green: 0.671, blue: 0.710).opacity(0.5)
    private static let _lightShadowLight = Color.white.opacity(0.7)
    private static let _lightTextPrimary = Color(red: 0.12, green: 0.12, blue: 0.14)        // #1F1F24
    private static let _lightTextSecondary = Color(red: 0.45, green: 0.45, blue: 0.50)      // #737380
    private static let _lightCardBg = Color(red: 0.949, green: 0.949, blue: 0.961)

    // MARK: - Dark Mode
    private static let _darkBackground = Color(red: 0.11, green: 0.11, blue: 0.14)          // #1C1C24
    private static let _darkSurface = Color(red: 0.15, green: 0.15, blue: 0.18)             // #26262E
    private static let _darkShadowDark = Color.black.opacity(0.6)
    private static let _darkShadowLight = Color.white.opacity(0.06)
    private static let _darkTextPrimary = Color(red: 0.95, green: 0.95, blue: 0.97)         // #F2F2F5
    private static let _darkTextSecondary = Color(red: 0.60, green: 0.60, blue: 0.65)       // #9999A6
    private static let _darkCardBg = Color(red: 0.15, green: 0.15, blue: 0.18)

    // MARK: - Adaptive Colors (respond to colorScheme)

    static var background: Color {
        Color(light: _lightBackground, dark: _darkBackground)
    }
    static var surface: Color {
        Color(light: _lightSurface, dark: _darkSurface)
    }
    static var shadowDark: Color {
        Color(light: _lightShadowDark, dark: _darkShadowDark)
    }
    static var shadowLight: Color {
        Color(light: _lightShadowLight, dark: _darkShadowLight)
    }
    static var textPrimary: Color {
        Color(light: _lightTextPrimary, dark: _darkTextPrimary)
    }
    static var textSecondary: Color {
        Color(light: _lightTextSecondary, dark: _darkTextSecondary)
    }
    static var cardBg: Color {
        Color(light: _lightCardBg, dark: _darkCardBg)
    }

    // MARK: - Accent (same in both modes, slightly adjusted for dark)

    static let accent = Color(red: 0.831, green: 0.635, blue: 0.227)          // #d4a23a
    static let accentLight = Color(red: 0.910, green: 0.745, blue: 0.353)     // #e8be5a

    static var accentAdaptive: Color {
        Color(light: accent, dark: accentLight)
    }

    // MARK: - Semantic Colors

    static var success: Color {
        Color(light: Color(red: 0.20, green: 0.78, blue: 0.35), dark: Color(red: 0.30, green: 0.85, blue: 0.45))
    }
    static var error: Color {
        Color(light: Color(red: 0.90, green: 0.22, blue: 0.21), dark: Color(red: 0.95, green: 0.35, blue: 0.30))
    }

    // MARK: - Compatibility

    static var primary: Color { textPrimary }
    static var primaryLight: Color { textSecondary }
}

// MARK: - Color Extension for Light/Dark

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Neumorphic Modifiers (Dark Mode Aware)

struct NeumorphicRaised: ViewModifier {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.background)
                    .shadow(color: AppColors.shadowDark, radius: 8, x: 6, y: 6)
                    .shadow(color: AppColors.shadowLight, radius: 8, x: -6, y: -6)
            )
    }
}

struct NeumorphicPressed: ViewModifier {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                    .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)
            )
    }
}

// MARK: - Neumorphic Inset (for dark mode depth effect)

struct NeumorphicInset: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.background)
                    .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 4, x: 4, y: 4)
                    .shadow(color: AppColors.shadowLight.opacity(0.3), radius: 4, x: -4, y: -4)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func neumorphicRaised(cornerRadius: CGFloat = 20) -> some View {
        modifier(NeumorphicRaised(cornerRadius: cornerRadius))
    }

    func neumorphicPressed(cornerRadius: CGFloat = 20) -> some View {
        modifier(NeumorphicPressed(cornerRadius: cornerRadius))
    }

    func neumorphicInset(cornerRadius: CGFloat = 20) -> some View {
        modifier(NeumorphicInset(cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Definitions

enum AppGradients {
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.accent, AppColors.accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var subtleAccentGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.accent.opacity(0.3), AppColors.accentLight.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Haptic Feedback

enum HapticManager {
    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
