import UIKit
import AVFoundation

/// Extracts and caches album artwork from MP3 files (ID3 tags)
class ArtworkService: ObservableObject {
    static let shared = ArtworkService()

    private var cache = NSCache<NSURL, UIImage>()
    private var loadingURLs = Set<URL>()

    init() {
        cache.countLimit = 200
    }

    /// Returns cached artwork or nil. Starts async load if not cached.
    func artwork(for url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }

        // Don't duplicate requests
        guard !loadingURLs.contains(url) else {
            completion(nil)
            return
        }
        loadingURLs.insert(url)

        Task.detached(priority: .utility) { [weak self] in
            let image = await self?.extractArtwork(from: url)
            await MainActor.run {
                self?.loadingURLs.remove(url)
                if let image = image {
                    self?.cache.setObject(image, forKey: url as NSURL)
                }
                completion(image)
            }
        }
    }

    /// Synchronous cache lookup only
    func cachedArtwork(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    private func extractArtwork(from url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        do {
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                guard let key = item.commonKey, key == .commonKeyArtwork else { continue }
                if let data = try await item.load(.dataValue),
                   let image = UIImage(data: data) {
                    return image
                }
            }
        } catch {
            // Silently fail — no artwork available
        }
        return nil
    }
}
