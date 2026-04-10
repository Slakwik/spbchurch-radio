import Foundation
import Combine

class DownloadManager: ObservableObject {
    @Published var downloads: [URL: DownloadState] = [:]
    @Published var downloadedTracks: Set<URL> = []

    private var activeTasks: [URL: URLSessionDownloadTask] = [:]

    enum DownloadState {
        case downloading(progress: Double)
        case completed
        case failed(Error)
    }

    static var downloadsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("OfflineTracks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func localFileURL(for track: Track) -> URL {
        // Use a hash of the remote URL to avoid filename conflicts
        let hash = track.url.absoluteString.data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(40)
        return downloadsDirectory.appendingPathComponent("\(hash).mp3")
    }

    init() {
        loadDownloadedTracks()
    }

    func loadDownloadedTracks() {
        let dir = Self.downloadsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        // We'll track by checking existence per-track instead
        downloadedTracks = []
    }

    func isDownloaded(_ track: Track) -> Bool {
        let localURL = Self.localFileURL(for: track)
        return FileManager.default.fileExists(atPath: localURL.path)
    }

    func localURL(for track: Track) -> URL? {
        let localURL = Self.localFileURL(for: track)
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    func download(_ track: Track) {
        guard activeTasks[track.url] == nil else { return }

        downloads[track.url] = .downloading(progress: 0)

        let task = URLSession.shared.downloadTask(with: track.url) { [weak self] tempURL, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activeTasks.removeValue(forKey: track.url)

                if let error = error {
                    self.downloads[track.url] = .failed(error)
                    return
                }

                guard let tempURL = tempURL else {
                    self.downloads[track.url] = .failed(URLError(.cannotCreateFile))
                    return
                }

                let dest = Self.localFileURL(for: track)
                do {
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    self.downloads[track.url] = .completed
                    self.downloadedTracks.insert(track.url)
                    self.objectWillChange.send()
                } catch {
                    self.downloads[track.url] = .failed(error)
                }
            }
        }

        activeTasks[track.url] = task
        task.resume()

        // Observe progress
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloads[track.url] = .downloading(progress: progress.fractionCompleted)
            }
        }
        // Store observation to keep it alive (simplified - in production use proper storage)
        objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }

    func cancelDownload(_ track: Track) {
        activeTasks[track.url]?.cancel()
        activeTasks.removeValue(forKey: track.url)
        downloads.removeValue(forKey: track.url)
    }

    func deleteDownload(_ track: Track) {
        let localURL = Self.localFileURL(for: track)
        try? FileManager.default.removeItem(at: localURL)
        downloads.removeValue(forKey: track.url)
        downloadedTracks.remove(track.url)
        objectWillChange.send()
    }
}
