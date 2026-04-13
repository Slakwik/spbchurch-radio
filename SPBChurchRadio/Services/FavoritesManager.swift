import Foundation
import Combine

/// Manages the user's favorite tracks — a simple playlist persisted to disk.
/// Storage is a JSON file in the Documents directory, so it survives app
/// updates and is independent of the remote catalog availability.
class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: [Track] = []

    private static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("favorites.json")
    }

    init() {
        load()
    }

    // MARK: - Queries

    func isFavorite(_ track: Track) -> Bool {
        favorites.contains { $0.url == track.url }
    }

    // MARK: - Mutations

    func toggle(_ track: Track) {
        if isFavorite(track) {
            remove(track)
        } else {
            add(track)
        }
    }

    func add(_ track: Track) {
        guard !isFavorite(track) else { return }
        favorites.append(track)
        save()
    }

    func remove(_ track: Track) {
        favorites.removeAll { $0.url == track.url }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let tracks = try? JSONDecoder().decode([Track].self, from: data) else {
            return
        }
        favorites = tracks
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
