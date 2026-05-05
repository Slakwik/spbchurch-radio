import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var navigator: AppNavigator
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var downloadedTracks: [Track] { downloadManager.downloadedTracks }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if downloadedTracks.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Загрузки")
            .navigationBarTitleDisplayMode(.large)
            .tint(AppColors.accentAdaptive)
        }
    }

    private var list: some View {
        List {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.accentAdaptive)
                Text("\(downloadedTracks.count) ОФЛАЙН")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 0, leading: hSizeClass == .regular ? 28 : 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(downloadedTracks) { track in
                DownloadedTrackRow(track: track)
                    .listRowInsets(EdgeInsets(top: 4, leading: hSizeClass == .regular ? 28 : 18, bottom: 4, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete { idx in
                for i in idx { downloadManager.deleteDownload(downloadedTracks[i]) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))

            Text("Нет загруженных треков")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Загрузите треки во вкладке «Треки»\nдля офлайн-прослушивания")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.lightImpact()
                navigator.go(to: .tracks)
            } label: {
                Text("Открыть треки")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppGradients.accentGradient))
            }
            .padding(.top, 6)
        }
        .padding()
    }
}

private struct DownloadedTrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.colorScheme) private var colorScheme

    private var isCurrent: Bool { radioPlayer.filePlayer.currentTrack?.url == track.url }
    private var isPlaying: Bool { isCurrent && radioPlayer.isFilePlaying }

    var body: some View {
        Button(action: play) {
            HStack(spacing: 14) {
                statusGlyph

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? AppColors.accentAdaptive : AppColors.textPrimary)
                        .lineLimit(2)

                    Label("На устройстве", systemImage: "internaldrive.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 4)

                actionsCluster
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .auroraSolid(cornerRadius: 16)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.accentAdaptive.opacity(isCurrent ? 0.5 : 0), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: isCurrent)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                HapticManager.lightImpact()
                downloadManager.deleteDownload(track)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private var statusGlyph: some View {
        ZStack {
            Circle()
                .fill(AppColors.success.opacity(0.15))
                .frame(width: 38, height: 38)

            if isPlaying {
                MiniEqualizerView(isPlaying: true, maxHeight: 14)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.success)
            }
        }
    }

    private var actionsCluster: some View {
        HStack(spacing: 14) {
            if let localURL = downloadManager.localURL(for: track) {
                ShareLink(item: localURL,
                          preview: SharePreview(track.title, image: Image(systemName: "music.note"))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .simultaneousGesture(TapGesture().onEnded { HapticManager.lightImpact() })
            }

            Button {
                HapticManager.lightImpact()
                downloadManager.deleteDownload(track)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppGradients.accentGradient))
                .shadow(color: AppColors.accent.opacity(0.3), radius: 6, y: 2)
        }
    }

    private func play() {
        HapticManager.mediumImpact()
        if isPlaying {
            radioPlayer.toggleFilePause()
        } else {
            let localURL = downloadManager.localURL(for: track)
            radioPlayer.playFile(track, localURL: localURL, queue: downloadManager.downloadedTracks)
        }
    }
}
