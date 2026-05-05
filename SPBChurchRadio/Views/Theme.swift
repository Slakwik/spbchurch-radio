import SwiftUI

// MARK: - Aurora Palette
//
// Editorial-glass design system. Moves away from heavy neumorphic shadows
// to native iOS material backgrounds with subtle hairline strokes and a
// decisive warm-bronze accent.

enum AppColors {
    // MARK: - Light Mode
    private static let _lightBackground = Color(red: 0.980, green: 0.980, blue: 0.969)   // #FAFAF7 — warm off-white
    private static let _lightSurface = Color.white                                        // pure white card
    private static let _lightStroke = Color(red: 0.902, green: 0.894, blue: 0.871)        // #E6E4DE — hairline
    private static let _lightTextPrimary = Color(red: 0.055, green: 0.055, blue: 0.071)   // #0E0E12
    private static let _lightTextSecondary = Color(red: 0.451, green: 0.439, blue: 0.416) // #73706A — warm gray

    // Legacy compatibility — neumorphic shadow tokens are kept but neutralised
    // (very low opacity) so any view still calling them won't crash.
    private static let _lightShadowDark = Color.black.opacity(0.08)
    private static let _lightShadowLight = Color.white.opacity(0.4)
    private static let _lightCardBg = Color.white

    // MARK: - Dark Mode
    private static let _darkBackground = Color(red: 0.055, green: 0.055, blue: 0.071)     // #0E0E12
    private static let _darkSurface = Color(red: 0.110, green: 0.110, blue: 0.133)        // #1C1C22
    private static let _darkStroke = Color(red: 0.165, green: 0.165, blue: 0.180)         // #2A2A2E
    private static let _darkTextPrimary = Color(red: 0.961, green: 0.957, blue: 0.941)    // #F5F4F0
    private static let _darkTextSecondary = Color(red: 0.612, green: 0.596, blue: 0.565)  // #9C9890
    private static let _darkShadowDark = Color.black.opacity(0.5)
    private static let _darkShadowLight = Color.white.opacity(0.04)
    private static let _darkCardBg = Color(red: 0.110, green: 0.110, blue: 0.133)

    // MARK: - Adaptive

    static var background: Color { Color(light: _lightBackground, dark: _darkBackground) }
    static var surface: Color { Color(light: _lightSurface, dark: _darkSurface) }
    static var stroke: Color { Color(light: _lightStroke, dark: _darkStroke) }
    static var textPrimary: Color { Color(light: _lightTextPrimary, dark: _darkTextPrimary) }
    static var textSecondary: Color { Color(light: _lightTextSecondary, dark: _darkTextSecondary) }
    static var cardBg: Color { Color(light: _lightCardBg, dark: _darkCardBg) }
    static var shadowDark: Color { Color(light: _lightShadowDark, dark: _darkShadowDark) }
    static var shadowLight: Color { Color(light: _lightShadowLight, dark: _darkShadowLight) }

    // MARK: - Accent (warm bronze, richer than the previous yellow-gold)

    static let accent = Color(red: 0.722, green: 0.518, blue: 0.165)          // #B8842A — bronze
    static let accentLight = Color(red: 0.851, green: 0.643, blue: 0.271)     // #D9A445

    static var accentAdaptive: Color {
        Color(light: accent, dark: accentLight)
    }

    /// Subtle background tint of the accent — for tonal buttons and active states.
    static var accentTinted: Color {
        Color(light: accent.opacity(0.10), dark: accentLight.opacity(0.18))
    }

    // MARK: - Semantic

    static var success: Color {
        Color(
            light: Color(red: 0.180, green: 0.490, blue: 0.357),
            dark:  Color(red: 0.298, green: 0.690, blue: 0.510)
        )
    }
    static var error: Color {
        Color(
            light: Color(red: 0.702, green: 0.227, blue: 0.227),
            dark:  Color(red: 0.851, green: 0.353, blue: 0.353)
        )
    }

    // MARK: - Compatibility (old API kept so all views still compile)

    static var primary: Color { textPrimary }
    static var primaryLight: Color { textSecondary }
}

// MARK: - Light/Dark color helper

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Aurora Card Modifiers

/// Editorial glass card — material background + hairline stroke + soft drop shadow.
/// Replaces the previous heavy neumorphic look across the app.
struct AuroraGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 22
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(AppColors.stroke, lineWidth: 1)
                    }
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04),
                radius: 14, x: 0, y: 6
            )
    }
}

/// Solid surface card — opaque white/dark with hairline stroke. For row backgrounds
/// where blur would compete with album art.
struct AuroraSolidCard: ViewModifier {
    var cornerRadius: CGFloat = 22
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(AppColors.stroke, lineWidth: 1)
                    }
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.03),
                radius: 10, x: 0, y: 4
            )
    }
}

/// Tonal pill — accent-tinted background, accent text. For secondary actions.
struct AuroraTonalPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(AppColors.accentTinted)
            }
            .foregroundStyle(AppColors.accentAdaptive)
    }
}

extension View {
    func auroraGlass(cornerRadius: CGFloat = 22) -> some View {
        modifier(AuroraGlassCard(cornerRadius: cornerRadius))
    }

    func auroraSolid(cornerRadius: CGFloat = 22) -> some View {
        modifier(AuroraSolidCard(cornerRadius: cornerRadius))
    }

    func auroraTonalPill() -> some View {
        modifier(AuroraTonalPill())
    }
}

// MARK: - Backwards compatibility shims for existing call sites

struct NeumorphicRaised: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content.modifier(AuroraGlassCard(cornerRadius: cornerRadius))
    }
}

struct NeumorphicPressed: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content.modifier(AuroraSolidCard(cornerRadius: cornerRadius))
    }
}

struct NeumorphicInset: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content.modifier(AuroraSolidCard(cornerRadius: cornerRadius))
    }
}

extension View {
    func neumorphicRaised(cornerRadius: CGFloat = 22) -> some View {
        modifier(NeumorphicRaised(cornerRadius: cornerRadius))
    }
    func neumorphicPressed(cornerRadius: CGFloat = 22) -> some View {
        modifier(NeumorphicPressed(cornerRadius: cornerRadius))
    }
    func neumorphicInset(cornerRadius: CGFloat = 22) -> some View {
        modifier(NeumorphicInset(cornerRadius: cornerRadius))
    }
}

// MARK: - Gradients

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
    static func lightImpact() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func mediumImpact() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Display Typography helpers

enum AppFonts {
    /// 44pt bold display — used as the screen title across tabs.
    static func display(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func sectionTitle() -> Font {
        .system(size: 13, weight: .semibold, design: .default)
    }
}
