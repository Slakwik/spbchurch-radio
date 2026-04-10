import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    private var downloadedTracks: [Track] {
        trackListVM.tracks.filter { downloadManager.isDownloaded($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if downloadedTracks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(downloadedTracks) { track in
                            DownloadedTrackRow(track: track)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                downloadManager.deleteDownload(downloadedTracks[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Загрузки")
            .toolbarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.tertiary)
                    .symbolRenderingMode(.hierarchical)
            }

            Text("Нет загруженных треков")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Загрузите треки во вкладке \"Треки\"\nдля офлайн-прослушивания")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isCurrentTrack
                        ? Color.accentColor.opacity(0.12)
                        : Color(.tertiarySystemFill)
                    )
                    .frame(width: 46, height: 46)

                if isCurrentTrack && radioPlayer.isFilePlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.accentColor)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: true)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isCurrentTrack ? .accentColor : .secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: isCurrentTrack ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isCurrentTrack ? Color.accentColor : .primary)
                    .lineLimit(2)

                HStack(spacing: 3) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 9))
                    Text("Сохранено на устройстве")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }

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
                    .font(.system(size: 28))
                    .foregroundStyle(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
