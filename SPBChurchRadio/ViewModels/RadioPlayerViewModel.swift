import Foundation
import Combine

class RadioPlayerViewModel: ObservableObject {
    @Published var radioService = RadioStreamService()
    @Published var filePlayer = FilePlayerService()
    @Published var activeMode: PlaybackMode = .none

    /// The full track list — set by TrackListViewModel for shuffle/next
    var allTracks: [Track] = []

    enum PlaybackMode {
        case none
        case radio
        case file
    }

    var isRadioPlaying: Bool { radioService.isPlaying }
    var isFilePlaying: Bool { filePlayer.isPlaying }
    var currentRadioTrack: String { radioService.currentTrackTitle }

    private var cancellables = Set<AnyCancellable>()

    /// Provides the DownloadManager for resolving local URLs
    var downloadManager: DownloadManager?

    init() {
        radioService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        filePlayer.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        // Auto-play next track when current finishes
        filePlayer.onTrackFinished = { [weak self] in
            self?.playNext()
        }
    }

    func toggleRadio() {
        if activeMode == .file {
            filePlayer.stop()
        }
        radioService.toggle()
        activeMode = radioService.isPlaying ? .radio : .none
    }

    func playFile(_ track: Track, localURL: URL? = nil) {
        if activeMode == .radio {
            radioService.stop()
        }
        filePlayer.play(track: track, localURL: localURL)
        activeMode = .file
    }

    func toggleFilePause() {
        filePlayer.togglePlayPause()
        if !filePlayer.isPlaying && filePlayer.currentTrack == nil {
            activeMode = .none
        }
    }

    func stopAll() {
        radioService.stop()
        filePlayer.stop()
        activeMode = .none
    }

    // MARK: - Next / Previous

    func playNext() {
        guard !allTracks.isEmpty else { return }

        if filePlayer.shuffle {
            // Random track, avoiding the current one
            let candidates = allTracks.filter { $0.url != filePlayer.currentTrack?.url }
            guard let next = candidates.randomElement() ?? allTracks.randomElement() else { return }
            let localURL = downloadManager?.localURL(for: next)
            playFile(next, localURL: localURL)
        } else {
            // Sequential: play the next track in the list
            if let current = filePlayer.currentTrack,
               let idx = allTracks.firstIndex(where: { $0.url == current.url }) {
                let nextIdx = (idx + 1) % allTracks.count
                let next = allTracks[nextIdx]
                let localURL = downloadManager?.localURL(for: next)
                playFile(next, localURL: localURL)
            }
        }
    }

    func playPrevious() {
        guard !allTracks.isEmpty else { return }

        // If more than 3 seconds in, restart current track
        if filePlayer.currentTime > 3 {
            filePlayer.seek(to: 0)
            return
        }

        if let current = filePlayer.currentTrack,
           let idx = allTracks.firstIndex(where: { $0.url == current.url }) {
            let prevIdx = idx > 0 ? idx - 1 : allTracks.count - 1
            let prev = allTracks[prevIdx]
            let localURL = downloadManager?.localURL(for: prev)
            playFile(prev, localURL: localURL)
        }
    }
}
