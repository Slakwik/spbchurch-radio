import SwiftUI

struct TrackListView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if trackListVM.isLoading {
                    loadingState
                } else if let error = trackListVM.errorMessage {
                    errorState(message: error)
                } else {
                    List {
                        // Track count header
                        if !trackListVM.filteredTracks.isEmpty {
                            HStack {
                                Text("\(trackListVM.filteredTracks.count) треков")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppColors.textSecondary)
                                Spacer()
                            }
                            .listRowInsets(EdgeInsets(
                                top: 4,
                                leading: hSizeClass == .regular ? 24 : 16,
                                bottom: 4,
                                trailing: hSizeClass == .regular ? 24 : 16
                            ))
                            .listRowBackground(Color.clear)
                        }

                        ForEach(trackListVM.filteredTracks) { track in
                            TrackRow(track: track)
                                .listRowInsets(EdgeInsets(
                                    top: 6,
                                    leading: hSizeClass == .regular ? 24 : 16,
                                    bottom: 6,
                                    trailing: hSizeClass == .regular ? 24 : 16
                                ))
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
            .tint(AppColors.accentAdaptive)
            .onAppear {
                trackListVM.loadTracks()
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 20) {
            // Animated loading dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    PulsingDot(delay: Double(i) * 0.3)
                }
            }
            Text("Загрузка треков...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 6, x: 4, y: 4)
                    .shadow(color: AppColors.shadowLight, radius: 6, x: -4, y: -4)

                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }

            Text(message)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                HapticManager.lightImpact()
                trackListVM.refresh()
            }) {
                Text("Повторить")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppGradients.accentGradient, in: Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Pulsing Dot (Loading Animation)

private struct PulsingDot: View {
    let delay: Double
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(AppColors.accentAdaptive)
            .frame(width: 10, height: 10)
            .scaleEffect(isPulsing ? 1.3 : 0.7)
            .opacity(isPulsing ? 1.0 : 0.4)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Track Row

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isCurrentTrack: Bool {
        radioPlayer.filePlayer.currentTrack?.url == track.url
    }

    private var isDownloaded: Bool {
        downloadManager.isDownloaded(track)
    }

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        HStack(spacing: isIPad ? 18 : 14) {
            trackThumbnail

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: isIPad ? 17 : 15, weight: isCurrentTrack ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isCurrentTrack ? AppColors.accentAdaptive : AppColors.textPrimary.opacity(0.85))
                    .lineLimit(2)

                if isDownloaded {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                        Text("Загружено")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: isIPad ? 20 : 16) {
                downloadButton
                playButton
            }
        }
        .padding(.vertical, isIPad ? 6 : 4)
        .padding(.horizontal, isCurrentTrack ? 10 : 0)
        .background(
            Group {
                if isCurrentTrack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.accentAdaptive.opacity(colorScheme == .dark ? 0.12 : 0.08))
                }
            }
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrentTrack)
    }

    private var trackThumbnail: some View {
        let thumbSize: CGFloat = isIPad ? 52 : 46
        return ZStack {
            ArtworkView(url: track.url, size: thumbSize, cornerRadius: isIPad ? 12 : 10)
                .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 4, x: 2, y: 2)
                .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 4, x: -2, y: -2)

            if isCurrentTrack && radioPlayer.isFilePlaying {
                RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                    .fill(AppColors.background.opacity(0.6))
                    .frame(width: thumbSize, height: thumbSize)

                // Mini equalizer instead of static waveform icon
                MiniEqualizerView(isPlaying: true, maxHeight: isIPad ? 18 : 14)
            } else if isCurrentTrack {
                // Show paused indicator
                RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                    .fill(AppColors.background.opacity(0.5))
                    .frame(width: thumbSize, height: thumbSize)

                Image(systemName: "pause.fill")
                    .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive)
            }
        }
    }

    @ViewBuilder
    private var downloadButton: some View {
        let iconSize: CGFloat = isIPad ? 26 : 22
        if isDownloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(AppColors.accentAdaptive.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
        } else if let state = downloadManager.downloads[track.url] {
            switch state {
            case .downloading(let progress):
                CircularProgressView(progress: progress)
                    .frame(width: iconSize, height: iconSize)
                    .onTapGesture {
                        HapticManager.lightImpact()
                        downloadManager.cancelDownload(track)
                    }
            case .completed:
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(AppColors.textSecondary)
                    .symbolRenderingMode(.hierarchical)
            case .failed:
                Button(action: {
                    HapticManager.lightImpact()
                    downloadManager.download(track)
                }) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(AppColors.error)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button(action: {
                HapticManager.lightImpact()
                downloadManager.download(track)
            }) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: iconSize))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var playButton: some View {
        Button(action: playTrack) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: isIPad ? 38 : 32, height: isIPad ? 38 : 32)
                    .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 3, x: 2, y: 2)
                    .shadow(color: AppColors.shadowLight.opacity(0.6), radius: 3, x: -2, y: -2)

                Image(systemName: isCurrentTrack && radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                    .foregroundStyle(isCurrentTrack ? AppColors.accentAdaptive : AppColors.textPrimary)
                    .offset(x: isCurrentTrack && radioPlayer.isFilePlaying ? 0 : 1)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(NeumorphicButtonStyle())
    }

    private func playTrack() {
        HapticManager.mediumImpact()
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
                .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppGradients.accentGradient,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
        }
    }
}
