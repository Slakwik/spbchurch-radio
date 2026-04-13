import Foundation

class TrackListViewModel: ObservableObject {
    enum SortOrder: String, CaseIterable, Identifiable {
        case `default` = "default"
        case titleAsc = "titleAsc"
        case titleDesc = "titleDesc"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .default:    return "По умолчанию"
            case .titleAsc:   return "По названию (А–Я)"
            case .titleDesc:  return "По названию (Я–А)"
            }
        }

        var iconName: String {
            switch self {
            case .default:    return "list.bullet"
            case .titleAsc:   return "arrow.up"
            case .titleDesc:  return "arrow.down"
            }
        }
    }

    @Published var tracks: [Track] = []
    @Published var filteredTracks: [Track] = []
    @Published var searchText = "" {
        didSet { filterTracks() }
    }
    @Published var sortOrder: SortOrder {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: "track_sort_order")
            filterTracks()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = TrackListService()

    init() {
        let saved = UserDefaults.standard.string(forKey: "track_sort_order") ?? SortOrder.default.rawValue
        self.sortOrder = SortOrder(rawValue: saved) ?? .default
    }

    func loadTracks() {
        guard tracks.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await service.fetchTracks()
                await MainActor.run {
                    self.tracks = fetched
                    self.filterTracks()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func filterTracks() {
        let base: [Track]
        if searchText.isEmpty {
            base = tracks
        } else {
            let query = searchText.lowercased()
            base = tracks.filter { $0.title.lowercased().contains(query) }
        }

        switch sortOrder {
        case .default:
            filteredTracks = base
        case .titleAsc:
            filteredTracks = base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDesc:
            filteredTracks = base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
    }

    func refresh() {
        tracks = []
        loadTracks()
    }
}
