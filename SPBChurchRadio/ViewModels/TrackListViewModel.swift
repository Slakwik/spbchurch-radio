import Foundation

class TrackListViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var filteredTracks: [Track] = []
    @Published var searchText = "" {
        didSet { filterTracks() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = TrackListService()

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
        if searchText.isEmpty {
            filteredTracks = tracks
        } else {
            let query = searchText.lowercased()
            filteredTracks = tracks.filter { $0.title.lowercased().contains(query) }
        }
    }

    func refresh() {
        tracks = []
        loadTracks()
    }
}
