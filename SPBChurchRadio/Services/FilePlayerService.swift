import Foundation
import AVFoundation
import MediaPlayer
import Combine

class FilePlayerService: ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?

    @Published var isPlaying = false
    @Published var currentTrack: Track?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = false

    func play(track: Track, localURL: URL? = nil) {
        stop()
        isLoading = true
        currentTrack = track

        let url = localURL ?? track.url
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        // Buffer ~1 minute for remote files
        if localURL == nil {
            item.preferredForwardBufferDuration = 60
        }

        player = AVPlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = true

        // Observe when ready to play
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.isLoading = false
                    self?.duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
                }
            }
            .store(in: &cancellables)

        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        player?.play()
        isPlaying = true
        setupTimeObserver()
        updateNowPlaying()
        setupRemoteCommands()
    }

    func togglePlayPause() {
        guard player != nil else { return }
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        duration = 0
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateNowPlaying()
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds.isFinite ? time.seconds : 0
            if let item = self.player?.currentItem {
                let dur = item.duration.seconds
                if dur.isFinite && dur > 0 {
                    self.duration = dur
                }
            }
        }
    }

    @objc private func playerDidFinish() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = self.duration
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = "SPBChurch Radio"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    deinit {
        stop()
    }
}
