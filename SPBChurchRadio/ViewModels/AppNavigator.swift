import Foundation

/// Shared navigation state — lets any view switch the root tab and coordinate
/// cross-tab actions (e.g. "find this track in the Tracks tab").
class AppNavigator: ObservableObject {
    @Published var selectedTab: Int = 0

    enum Tab: Int {
        case radio = 0
        case tracks = 1
        case downloads = 2
        case settings = 3
    }

    func go(to tab: Tab) {
        selectedTab = tab.rawValue
    }
}

// MARK: - Radio title cleaning

enum RadioTitle {
    /// Strips station branding ("SPBChurch Radio", "Церковь Преображение", etc.)
    /// and any leading/trailing separators so the result is suitable as a
    /// search query for the Tracks tab.
    static func cleaned(_ raw: String) -> String {
        let noise: [String] = [
            "SPBChurch Radio",
            "SPB Church Radio",
            "Церковь Преображение",
            "Церковь «Преображение»",
            "Преображение"
        ]

        var result = raw
        for token in noise {
            result = result.replacingOccurrences(
                of: token,
                with: "",
                options: .caseInsensitive
            )
        }

        // Strip common separators that may be left dangling
        let separators = CharacterSet(charactersIn: "-–—|:·•*\t \u{00A0}")
        while let first = result.unicodeScalars.first, separators.contains(first) {
            result.removeFirst()
        }
        while let last = result.unicodeScalars.last, separators.contains(last) {
            result.removeLast()
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if the title is something a user could reasonably search
    /// for (i.e. not empty, not the "no data" placeholder, not just branding).
    static func isSearchable(_ raw: String) -> Bool {
        let cleaned = cleaned(raw)
        guard !cleaned.isEmpty else { return false }
        let placeholders = ["нет данных", "offline", "—", "-"]
        return !placeholders.contains(cleaned.lowercased())
    }
}
