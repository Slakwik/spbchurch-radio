import SwiftUI

struct TrackListView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if trackListVM.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Загрузка треков...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = trackListVM.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Повторить") {
                            trackListVM.refresh()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(trackListVM.filteredTracks) { track in
                            TrackRow(track: track)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        trackListVM.refresh()
                    }
                }
            }
            .navigationTitle("Треки")
            .searchable(text: $trackListVM.searchText, prompt: "Поиск треков...")
            .onAppear {
                trackListVM.loadTracks()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    private var isCurrentTrack: Bool {
        radioPlayer.filePlayer.currentTrack?.url == track.url
    }

    private var isDownloaded: Bool {
        downloadManager.isDownloaded(track)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play indicator or music icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentTrack
                          ? Color.accentColor.opacity(0.15)
                          : Color(UIColor.tertiarySystemFill))
                    .frame(width: 44, height: 44)

                if isCurrentTrack && radioPlayer.isFilePlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.accentColor)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(isCurrentTrack ? .accentColor : .secondary)
                }
            }

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline)
                    .fontWeight(isCurrentTrack ? .semibold : .regular)
                    .foregroundColor(isCurrentTrack ? .accentColor : .primary)
                    .lineLimit(2)

                if isDownloaded {
                    Label("Загружено", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Download button
            downloadButton

            // Play button
            Button(action: playTrack) {
                Image(systemName: isCurrentTrack && radioPlayer.isFilePlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var downloadButton: some View {
        if isDownloaded {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        } else if let state = downloadManager.downloads[track.url] {
            switch state {
            case .downloading(let progress):
                ZStack {
                    CircularProgressView(progress: progress)
                        .frame(width: 24, height: 24)
                }
                .onTapGesture {
                    downloadManager.cancelDownload(track)
                }
            case .completed:
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            case .failed:
                Button(action: { downloadManager.download(track) }) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button(action: { downloadManager.download(track) }) {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private func playTrack() {
        if isCurrentTrack && radioPlayer.isFilePlaying {
            radioPlayer.toggleFilePause()
        } else {
            let localURL = downloadManager.localURL(for: track)
            radioPlayer.playFile(track, localURL: localURL)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
