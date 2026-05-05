import Foundation

class TrackListService {
    private let listURL = URL(string: "https://station.spbchurch.ru/mp3/mp3_files_list.html")!

    func fetchTracks() async throws -> [Track] {
        do {
            let (data, _) = try await URLSession.shared.data(from: listURL)
            guard let html = String(data: data, encoding: .utf8) else {
                await MainActor.run {
                    LogManager.shared.error("Не удалось декодировать каталог", source: "Catalog")
                }
                throw URLError(.cannotDecodeContentData)
            }
            let tracks = parseTrackList(from: html)
            await MainActor.run {
                LogManager.shared.info("Каталог загружен: \(tracks.count) треков", source: "Catalog")
            }
            return tracks
        } catch {
            await MainActor.run {
                LogManager.shared.error("Загрузка каталога: \(error.localizedDescription)", source: "Catalog")
            }
            throw error
        }
    }

    private func parseTrackList(from html: String) -> [Track] {
        var tracks = [Track]()
        var seenURLs = Set<URL>()

        // Parse <a href="...">Title</a> within <li> elements
        let pattern = #"<a\s+href="([^"]+\.mp3)"[^>]*>([^<]+)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return tracks
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsHTML.length))

        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }

            let urlString = nsHTML.substring(with: match.range(at: 1))
            let title = nsHTML.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Handle both absolute and relative URLs
            let url: URL?
            if urlString.hasPrefix("http") {
                url = URL(string: urlString)
            } else {
                url = URL(string: "https://station.spbchurch.ru/mp3/\(urlString)")
            }

            // Dedupe: the catalog HTML occasionally lists the same MP3 file
            // twice with slightly different anchor text. Keep only the first
            // occurrence — different display titles for the same audio file
            // would just confuse the download/playback state which is keyed
            // by URL anyway.
            if let url = url, seenURLs.insert(url).inserted {
                tracks.append(Track(title: title, url: url))
            }
        }

        return tracks
    }
}
