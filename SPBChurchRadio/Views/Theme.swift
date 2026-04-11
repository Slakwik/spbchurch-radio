import SwiftUI

/// Neumorphic color palette inspired by AirOS Music Player
enum AppColors {
    // Neumorphic base
    static let background = Color(red: 0.941, green: 0.941, blue: 0.953)      // #F0F0F3
    static let surface = Color(red: 0.949, green: 0.949, blue: 0.961)         // #F2F2F5

    // Shadows
    static let shadowLight = Color.white.opacity(0.7)
    static let shadowDark = Color(red: 0.659, green: 0.671, blue: 0.710).opacity(0.5) // #A8ABB5

    // Text
    static let textPrimary = Color(red: 0.12, green: 0.12, blue: 0.14)        // #1F1F24
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.50)      // #737380

    // Accent — keep gold for brand identity
    static let accent = Color(red: 0.831, green: 0.635, blue: 0.227)          // #d4a23a
    static let accentLight = Color(red: 0.910, green: 0.745, blue: 0.353)     // #e8be5a

    // Card / raised elements
    static let cardBg = Color(red: 0.949, green: 0.949, blue: 0.961)

    // For compatibility
    static let primary = textPrimary
    static let primaryLight = textSecondary
}

// MARK: - Neumorphic Modifiers

struct NeumorphicRaised: ViewModifier {
    var cornerRadius: CGFloat = 20

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

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                    .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)
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
}
