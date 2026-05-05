import Foundation
import CommonCrypto
import Combine

class DownloadManager: ObservableObject {
    @Published var downloads: [URL: DownloadState] = [:]

    /// Persisted list of tracks with completed downloads — available even when
    /// the remote catalog has not been fetched yet.
    @Published private(set) var downloadedTracks: [Track] = []

    private var activeTasks: [URL: URLSessionDownloadTask] = [:]

    enum DownloadState {
        case downloading(progress: Double)
        case completed
        case failed(Error)
    }

    /// Ephemeral session — no shared cache, no cookies, no credential store.
    /// We tried the default session to leverage HTTP/2 multiplexing, but in
    /// practice the keep-alive sockets from a previous download still cause a
    /// noticeable delay before the next user-initiated download starts.
    /// Ephemeral guarantees a clean connection state per task.
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()

    init() {
        loadMetadata()
    }

    // MARK: - Paths

    static var downloadsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("OfflineTracks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var metadataFileURL: URL {
        downloadsDirectory.appendingPathComponent("downloads.json")
    }

    static func localFileURL(for track: Track) -> URL {
        let data = Data(track.url.absoluteString.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return downloadsDirectory.appendingPathComponent("\(hex).mp3")
    }

    // MARK: - Queries

    func isDownloaded(_ track: Track) -> Bool {
        FileManager.default.fileExists(atPath: Self.localFileURL(for: track).path)
    }

    func localURL(for track: Track) -> URL? {
        let url = Self.localFileURL(for: track)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Download

    func download(_ track: Track) {
        // If the file is already on disk, just sync state — nothing to do.
        if isDownloaded(track) {
            downloads[track.url] = .completed
            registerDownloaded(track)
            Task { @MainActor in LogManager.shared.info("Уже на диске: «\(track.title)»", source: "Downloads") }
            return
        }

        // Re-tapping while a download is already in flight is a no-op. (Failed
        // and completed states fall through to a fresh attempt because their
        // task is gone from activeTasks.)
        if activeTasks[track.url] != nil {
            return
        }

        Task { @MainActor in LogManager.shared.info("Старт загрузки: «\(track.title)»", source: "Downloads") }

        // Clear any stale .failed marker before starting fresh — the UI shows
        // an exclamation glyph for .failed; we want it gone the moment retry
        // begins, not after the next progress tick.
        downloads[track.url] = .downloading(progress: 0)

        // Per-request fresh connection — explicitly tell the server not to
        // keep the socket alive, so the next user-initiated download isn't
        // stuck waiting for an OS-level keep-alive timeout.
        var request = URLRequest(
            url: track.url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30
        )
        request.setValue("close", forHTTPHeaderField: "Connection")

        let task = session.downloadTask(with: request) { [weak self] tempURL, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activeTasks.removeValue(forKey: track.url)

                if let error = error {
                    // Cancellation isn't a failure to surface — clear silently.
                    if (error as NSError).code == NSURLErrorCancelled {
                        self.downloads.removeValue(forKey: track.url)
                        LogManager.shared.info("Загрузка отменена: «\(track.title)»", source: "Downloads")
                    } else {
                        self.downloads[track.url] = .failed(error)
                        LogManager.shared.error("Загрузка не удалась: «\(track.title)» — \(error.localizedDescription)", source: "Downloads")
                    }
                    return
                }

                guard let tempURL = tempURL else {
                    self.downloads[track.url] = .failed(URLError(.cannotCreateFile))
                    LogManager.shared.error("Нет файла после загрузки: «\(track.title)»", source: "Downloads")
                    return
                }

                let dest = Self.localFileURL(for: track)
                do {
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    self.downloads[track.url] = .completed
                    self.registerDownloaded(track)
                    self.objectWillChange.send()
                    LogManager.shared.info("Загружено: «\(track.title)»", source: "Downloads")
                } catch {
                    self.downloads[track.url] = .failed(error)
                    LogManager.shared.error("Ошибка перемещения файла: «\(track.title)» — \(error.localizedDescription)", source: "Downloads")
                }
            }
        }

        activeTasks[track.url] = task
        task.resume()

        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                // Don't overwrite a terminal state if the observer fires late.
                guard let self = self else { return }
                if case .completed = self.downloads[track.url] { return }
                if case .failed = self.downloads[track.url] { return }
                self.downloads[track.url] = .downloading(progress: progress.fractionCompleted)
            }
        }
        objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }

    func cancelDownload(_ track: Track) {
        activeTasks[track.url]?.cancel()
        activeTasks.removeValue(forKey: track.url)
        downloads.removeValue(forKey: track.url)
    }

    func deleteDownload(_ track: Track) {
        // Cancel any in-flight task before removing the file so the completion
        // handler doesn't race a fresh download.
        activeTasks[track.url]?.cancel()
        activeTasks.removeValue(forKey: track.url)
        try? FileManager.default.removeItem(at: Self.localFileURL(for: track))
        downloads.removeValue(forKey: track.url)
        unregisterDownloaded(track)
        objectWillChange.send()
        Task { @MainActor in LogManager.shared.info("Удалено с устройства: «\(track.title)»", source: "Downloads") }
    }

    // MARK: - Metadata persistence

    private func loadMetadata() {
        let url = Self.metadataFileURL
        guard let data = try? Data(contentsOf: url),
              let tracks = try? JSONDecoder().decode([Track].self, from: data) else {
            return
        }
        // Drop entries whose files have been removed from disk out-of-band
        downloadedTracks = tracks.filter { isDownloaded($0) }
        if downloadedTracks.count != tracks.count {
            saveMetadata()
        }
    }

    private func saveMetadata() {
        let url = Self.metadataFileURL
        guard let data = try? JSONEncoder().encode(downloadedTracks) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func registerDownloaded(_ track: Track) {
        if let idx = downloadedTracks.firstIndex(where: { $0.url == track.url }) {
            downloadedTracks[idx] = track
        } else {
            downloadedTracks.append(track)
        }
        saveMetadata()
    }

    private func unregisterDownloaded(_ track: Track) {
        downloadedTracks.removeAll { $0.url == track.url }
        saveMetadata()
    }

    /// Opportunistic backfill: when the remote catalog arrives, record any
    /// tracks whose files already exist on disk but are missing from metadata
    /// (e.g. downloaded in a pre-v3.5 build without persisted metadata).
    func backfillMetadata(from catalog: [Track]) {
        var added = false
        for track in catalog where isDownloaded(track) {
            if !downloadedTracks.contains(where: { $0.url == track.url }) {
                downloadedTracks.append(track)
                added = true
            }
        }
        if added { saveMetadata() }
    }
}
