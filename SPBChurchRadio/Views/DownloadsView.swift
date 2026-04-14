import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var downloadedTracks: [Track] {
        downloadManager.downloadedTracks
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if downloadedTracks.isEmpty {
                    emptyState
                } else {
                    List {
                        // Downloads count header
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.accentAdaptive)
                            Text("\(downloadedTracks.count) загружено")
                                .font(.system(size: 13, weight: .medium))
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

                        ForEach(downloadedTracks) { track in
                            DownloadedTrackRow(track: track)
                                .listRowInsets(EdgeInsets(
                                    top: 6,
                                    leading: hSizeClass == .regular ? 24 : 16,
                                    bottom: 6,
                                    trailing: hSizeClass == .regular ? 24 : 16
                                ))
                                .listRowBackground(Color.clear)
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
            .tint(AppColors.accentAdaptive)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 6, x: 4, y: 4)
                    .shadow(color: AppColors.shadowLight, radius: 6, x: -4, y: -4)

                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }

            Text("Нет загруженных треков")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Загрузите треки во вкладке \"Треки\"\nдля офлайн-прослушивания")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct DownloadedTrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isCurrentTrack: Bool {
        radioPlayer.filePlayer.currentTrack?.url == track.url
    }

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        HStack(spacing: isIPad ? 18 : 14) {
            ZStack {
                let thumbSize: CGFloat = isIPad ? 52 : 46
                ArtworkView(url: track.url, size: thumbSize, cornerRadius: isIPad ? 12 : 10)
                    .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 4, x: 2, y: 2)
                    .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 4, x: -2, y: -2)

                if isCurrentTrack && radioPlayer.isFilePlaying {
                    let thumbSize: CGFloat = isIPad ? 52 : 46
                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                        .fill(AppColors.background.opacity(0.6))
                        .frame(width: thumbSize, height: thumbSize)

                    MiniEqualizerView(isPlaying: true, maxHeight: isIPad ? 18 : 14)
                } else if isCurrentTrack {
                    let thumbSize: CGFloat = isIPad ? 52 : 46
                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                        .fill(AppColors.background.opacity(0.5))
                        .frame(width: thumbSize, height: thumbSize)

                    Image(systemName: "pause.fill")
                        .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: isIPad ? 17 : 15, weight: isCurrentTrack ? .semibold : .regular))
                    .foregroundStyle(isCurrentTrack ? AppColors.accentAdaptive : AppColors.textPrimary.opacity(0.85))
                    .lineLimit(2)

                HStack(spacing: 3) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 9))
                    Text("Сохранено на устройстве")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Share button
            if let localURL = downloadManager.localURL(for: track) {
                ShareLink(
                    item: localURL,
                    preview: SharePreview(track.title, image: Image(systemName: "music.note"))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive.opacity(0.8))
                }
                .simultaneousGesture(TapGesture().onEnded { HapticManager.lightImpact() })
            }

            // Delete button
            Button(action: {
                HapticManager.lightImpact()
                downloadManager.deleteDownload(track)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticManager.mediumImpact()
                if isCurrentTrack && radioPlayer.isFilePlaying {
                    radioPlayer.toggleFilePause()
                } else {
                    let localURL = downloadManager.localURL(for: track)
                    radioPlayer.playFile(track, localURL: localURL, queue: downloadManager.downloadedTracks)
                }
            }) {
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
}
