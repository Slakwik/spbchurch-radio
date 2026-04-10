import Foundation

class TrackListService {
    private let listURL = URL(string: "https://station.spbchurch.ru/mp3/mp3_files_list.html")!

    func fetchTracks() async throws -> [Track] {
        let (data, _) = try await URLSession.shared.data(from: listURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return parseTrackList(from: html)
    }

    private func parseTrackList(from html: String) -> [Track] {
        var tracks = [Track]()

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

            if let url = url {
                tracks.append(Track(title: title, url: url))
            }
        }

        return tracks
    }
}
