import Foundation
import Combine

class RadioPlayerViewModel: ObservableObject {
    @Published var radioService = RadioStreamService()
    @Published var filePlayer = FilePlayerService()
    @Published var activeMode: PlaybackMode = .none

    /// The full track catalog — set by TrackListViewModel. Used as a fallback
    /// queue when the caller doesn't provide an explicit one.
    var allTracks: [Track] = []

    /// The active playback queue — whatever list the user started playback
    /// from (Tracks, Favorites, Downloads, filtered search, etc.). Used by
    /// next/previous/auto-advance so playback stays within that context.
    @Published var playbackQueue: [Track] = []

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

        // Auto-advance when the current track finishes
        filePlayer.onTrackFinished = { [weak self] in
            self?.autoAdvance()
        }
    }

    /// Called automatically when a track finishes playing.
    /// Honors `playOnce` by stopping at the end of the queue instead of wrapping.
    private func autoAdvance() {
        let list = activeQueue
        guard !list.isEmpty else { return }

        switch filePlayer.order {
        case .shuffle, .repeatAll:
            playNext()
        case .playOnce:
            // If the current track is the last one in the queue, stop.
            if let current = filePlayer.currentTrack,
               let idx = list.firstIndex(where: { $0.url == current.url }),
               idx == list.count - 1 {
                filePlayer.stop()
                activeMode = .none
            } else {
                playNext()
            }
        }
    }

    func toggleRadio() {
        if activeMode == .file {
            filePlayer.stop()
        }
        radioService.toggle()
        activeMode = radioService.isPlaying ? .radio : .none
    }

    func playFile(_ track: Track, localURL: URL? = nil, queue: [Track]? = nil) {
        if activeMode == .radio {
            radioService.stop()
        }
        if let queue = queue, !queue.isEmpty {
            playbackQueue = queue
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

    /// The list used for navigation. Prefer the explicit playbackQueue; fall
    /// back to the full catalog so old behavior still works when nothing is
    /// set yet (e.g. lock-screen commands after a cold start).
    private var activeQueue: [Track] {
        !playbackQueue.isEmpty ? playbackQueue : allTracks
    }

    func playNext() {
        let list = activeQueue
        guard !list.isEmpty else { return }

        if filePlayer.shuffle {
            let candidates = list.filter { $0.url != filePlayer.currentTrack?.url }
            guard let next = candidates.randomElement() ?? list.randomElement() else { return }
            let localURL = downloadManager?.localURL(for: next)
            playFile(next, localURL: localURL)
        } else {
            if let current = filePlayer.currentTrack,
               let idx = list.firstIndex(where: { $0.url == current.url }) {
                let nextIdx = (idx + 1) % list.count
                let next = list[nextIdx]
                let localURL = downloadManager?.localURL(for: next)
                playFile(next, localURL: localURL)
            } else if let first = list.first {
                // Current track isn't in the queue — start from the top.
                let localURL = downloadManager?.localURL(for: first)
                playFile(first, localURL: localURL)
            }
        }
    }

    func playPrevious() {
        let list = activeQueue
        guard !list.isEmpty else { return }

        if filePlayer.currentTime > 3 {
            filePlayer.seek(to: 0)
            return
        }

        if let current = filePlayer.currentTrack,
           let idx = list.firstIndex(where: { $0.url == current.url }) {
            let prevIdx = idx > 0 ? idx - 1 : list.count - 1
            let prev = list[prevIdx]
            let localURL = downloadManager?.localURL(for: prev)
            playFile(prev, localURL: localURL)
        }
    }
}
