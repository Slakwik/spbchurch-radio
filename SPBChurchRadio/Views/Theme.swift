import SwiftUI

/// Color palette from spbchurch.ru
enum AppColors {
    // Primary — deep navy
    static let primary = Color(red: 0.059, green: 0.122, blue: 0.239)       // #0f1f3d
    static let primaryLight = Color(red: 0.118, green: 0.227, blue: 0.431)  // #1e3a6e

    // Accent — warm gold
    static let accent = Color(red: 0.831, green: 0.635, blue: 0.227)        // #d4a23a
    static let accentLight = Color(red: 0.910, green: 0.745, blue: 0.353)   // #e8be5a

    // Backgrounds — warm beige
    static let background = Color(red: 0.961, green: 0.953, blue: 0.937)    // #f5f3ef
    static let surface = Color(red: 0.980, green: 0.973, blue: 0.961)       // #faf8f5
    static let cardBg = Color.white

    // Text
    static let textPrimary = Color(red: 0.102, green: 0.102, blue: 0.180)   // #1a1a2e
    static let textSecondary = Color(red: 0.353, green: 0.353, blue: 0.478) // #5a5a7a
}
