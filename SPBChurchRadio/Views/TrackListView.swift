import SwiftUI

struct TrackListView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if trackListVM.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppColors.accent)
                        Text("Загрузка треков...")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } else if let error = trackListVM.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            .symbolRenderingMode(.hierarchical)
                        Text(error)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button(action: { trackListVM.refresh() }) {
                            Text("Повторить")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(AppColors.accent, in: Capsule())
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(trackListVM.filteredTracks) { track in
                            TrackRow(track: track)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        trackListVM.refresh()
                    }
                }
            }
            .navigationTitle("Треки")
            .toolbarTitleDisplayMode(.large)
            .searchable(text: $trackListVM.searchText, prompt: "Поиск по названию...")
            .tint(AppColors.accent)
            .onAppear {
                trackListVM.loadTracks()
            }
        }
    }
}

// MARK: - Track Row

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
        HStack(spacing: 14) {
            trackThumbnail

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: isCurrentTrack ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isCurrentTrack ? AppColors.accent : AppColors.textPrimary)
                    .lineLimit(2)

                if isDownloaded {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                        Text("Загружено")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.green)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 16) {
                downloadButton
                playButton
            }
        }
        .padding(.vertical, 4)
    }

    private var trackThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isCurrentTrack
                    ? AppColors.accent.opacity(0.12)
                    : AppColors.surface
                )
                .frame(width: 46, height: 46)

            if isCurrentTrack && radioPlayer.isFilePlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: true)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isCurrentTrack ? AppColors.accent : AppColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var downloadButton: some View {
        if isDownloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
        } else if let state = downloadManager.downloads[track.url] {
            switch state {
            case .downloading(let progress):
                CircularProgressView(progress: progress)
                    .frame(width: 22, height: 22)
                    .onTapGesture { downloadManager.cancelDownload(track) }
            case .completed:
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
            case .failed:
                Button(action: { downloadManager.download(track) }) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button(action: { downloadManager.download(track) }) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var playButton: some View {
        Button(action: playTrack) {
            Image(systemName: isCurrentTrack && radioPlayer.isFilePlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
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

// MARK: - Progress Ring

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColors.accent,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
        }
    }
}
