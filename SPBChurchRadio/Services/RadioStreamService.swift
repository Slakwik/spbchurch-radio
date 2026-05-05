import Foundation
import AVFoundation
import MediaPlayer

class RadioStreamService: ObservableObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var metadataTimer: Timer?

    @Published var isPlaying = false
    @Published var currentTrackTitle = "Нет данных"
    @Published var isLoading = false

    private let streamURL = URL(string: "https://station.spbchurch.ru/radio")!
    private let metadataURL = URL(string: "https://station.spbchurch.ru/")!

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            LogManager.shared.error("Audio session: \(error.localizedDescription)", source: "Radio")
        }
    }

    func play() {
        isLoading = true
        LogManager.shared.info("Старт прямого эфира", source: "Radio")

        let asset = AVURLAsset(url: streamURL)
        playerItem = AVPlayerItem(asset: asset)

        // Buffer approximately 1 minute of audio
        playerItem?.preferredForwardBufferDuration = 60

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        player?.automaticallyWaitsToMinimizeStalling = true
        player?.play()
        isPlaying = true
        isLoading = false

        setupNowPlaying()
        startMetadataPolling()
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        stopMetadataPolling()
        clearNowPlaying()
        LogManager.shared.info("Эфир остановлен", source: "Radio")
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    // MARK: - Metadata Polling

    private func startMetadataPolling() {
        fetchMetadata()
        metadataTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.fetchMetadata()
        }
    }

    private func stopMetadataPolling() {
        metadataTimer?.invalidate()
        metadataTimer = nil
    }

    private func fetchMetadata() {
        var request = URLRequest(url: metadataURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                LogManager.shared.warn("Метаданные эфира: \(error.localizedDescription)", source: "Radio")
                return
            }
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }

            if let title = self?.parseCurrentTrack(from: html) {
                DispatchQueue.main.async {
                    let prev = self?.currentTrackTitle
                    self?.currentTrackTitle = title
                    self?.updateNowPlaying(title: title)
                    if prev != title {
                        LogManager.shared.info("Идёт: «\(title)»", source: "Radio")
                    }
                }
            }
        }.resume()
    }

    private func parseCurrentTrack(from html: String) -> String? {
        // Find "Currently playing:" then extract the next streamstats cell value
        guard let cpRange = html.range(of: "Currently playing:") else { return nil }
        let after = html[cpRange.upperBound...]
        // Find the streamstats cell content after "Currently playing:"
        guard let statsRange = after.range(of: "class=\"streamstats\">") else { return nil }
        let valueStart = after[statsRange.upperBound...]
        guard let endRange = valueStart.range(of: "</td>") else { return nil }
        let title = String(valueStart[..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    // MARK: - Now Playing Info

    private func setupNowPlaying() {
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
    }

    private func updateNowPlaying(title: String) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = "SPBChurch Radio"
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    deinit {
        stopMetadataPolling()
    }
}
