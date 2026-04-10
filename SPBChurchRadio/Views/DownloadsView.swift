import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    private var downloadedTracks: [Track] {
        trackListVM.tracks.filter { downloadManager.isDownloaded($0) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if downloadedTracks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Нет загруженных треков")
                            .foregroundColor(.secondary)
                        Text("Загрузите треки во вкладке \"Треки\"\nдля офлайн-прослушивания")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(downloadedTracks) { track in
                            DownloadedTrackRow(track: track)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                downloadManager.deleteDownload(downloadedTracks[index])
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Загрузки")
        }
        .navigationViewStyle(.stack)
    }
}

struct DownloadedTrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    private var isCurrentTrack: Bool {
        radioPlayer.filePlayer.currentTrack?.url == track.url
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentTrack
                          ? Color.accentColor.opacity(0.15)
                          : Color(UIColor.tertiarySystemFill))
                    .frame(width: 44, height: 44)

                Image(systemName: isCurrentTrack ? "waveform" : "music.note")
                    .foregroundColor(isCurrentTrack ? .accentColor : .secondary)
            }

            Text(track.title)
                .font(.subheadline)
                .fontWeight(isCurrentTrack ? .semibold : .regular)
                .lineLimit(2)

            Spacer()

            Button(action: {
                if isCurrentTrack && radioPlayer.isFilePlaying {
                    radioPlayer.toggleFilePause()
                } else {
                    let localURL = downloadManager.localURL(for: track)
                    radioPlayer.playFile(track, localURL: localURL)
                }
            }) {
                Image(systemName: isCurrentTrack && radioPlayer.isFilePlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
