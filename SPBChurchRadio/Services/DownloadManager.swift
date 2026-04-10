import Foundation
import CommonCrypto
import Combine

class DownloadManager: ObservableObject {
    @Published var downloads: [URL: DownloadState] = [:]

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
        // SHA-256 hash of the full URL — unique per track
        let data = Data(track.url.absoluteString.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return downloadsDirectory.appendingPathComponent("\(hex).mp3")
    }

    func isDownloaded(_ track: Track) -> Bool {
        FileManager.default.fileExists(atPath: Self.localFileURL(for: track).path)
    }

    func localURL(for track: Track) -> URL? {
        let url = Self.localFileURL(for: track)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
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
        objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }

    func cancelDownload(_ track: Track) {
        activeTasks[track.url]?.cancel()
        activeTasks.removeValue(forKey: track.url)
        downloads.removeValue(forKey: track.url)
    }

    func deleteDownload(_ track: Track) {
        try? FileManager.default.removeItem(at: Self.localFileURL(for: track))
        downloads.removeValue(forKey: track.url)
        objectWillChange.send()
    }
}
