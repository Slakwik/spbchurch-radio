import Foundation

struct Track: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let url: URL

    init(title: String, url: URL) {
        self.id = UUID()
        self.title = title
        self.url = url
    }

    var fileName: String {
        url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
    }

    var isDownloaded: Bool {
        let localURL = DownloadManager.localFileURL(for: self)
        return FileManager.default.fileExists(atPath: localURL.path)
    }
}
