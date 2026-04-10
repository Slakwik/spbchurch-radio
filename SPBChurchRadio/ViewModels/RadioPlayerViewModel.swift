import Foundation
import Combine

class RadioPlayerViewModel: ObservableObject {
    @Published var radioService = RadioStreamService()
    @Published var filePlayer = FilePlayerService()
    @Published var activeMode: PlaybackMode = .none

    enum PlaybackMode {
        case none
        case radio
        case file
    }

    var isRadioPlaying: Bool { radioService.isPlaying }
    var isFilePlaying: Bool { filePlayer.isPlaying }
    var currentRadioTrack: String { radioService.currentTrackTitle }

    private var cancellables = Set<AnyCancellable>()

    init() {
        radioService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        filePlayer.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
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
}
