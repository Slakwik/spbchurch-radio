import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var navigator: AppNavigator
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if favoritesManager.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favoritesManager.favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton().foregroundStyle(AppColors.accentAdaptive)
                    }
                }
            }
            .tint(AppColors.accentAdaptive)
        }
    }

    private var favoritesList: some View {
        List {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.accentAdaptive)
                Text("\(favoritesManager.favorites.count) ТРЕКОВ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 0, leading: hSizeClass == .regular ? 28 : 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(favoritesManager.favorites) { track in
                FavoriteTrackRow(track: track)
                    .listRowInsets(EdgeInsets(top: 4, leading: hSizeClass == .regular ? 28 : 18, bottom: 4, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete { idx in
                for i in idx { favoritesManager.remove(favoritesManager.favorites[i]) }
            }
            .onMove { src, dst in favoritesManager.move(from: src, to: dst) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.accentAdaptive.opacity(0.5))

            Text("Нет избранных треков")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Нажмите ♡ в строке трека\nили на экране плеера")
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

// MARK: - Favorite track row

private struct FavoriteTrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.colorScheme) private var colorScheme

    private var isCurrent: Bool { radioPlayer.filePlayer.currentTrack?.url == track.url }
    private var isPlaying: Bool { isCurrent && radioPlayer.isFilePlaying }
    private var isDownloaded: Bool { downloadManager.isDownloaded(track) }

    var body: some View {
        Button(action: play) {
            HStack(spacing: 14) {
                statusGlyph

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? AppColors.accentAdaptive : AppColors.textPrimary)
                        .lineLimit(2)

                    if isDownloaded {
                        Label("Загружен", systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(AppColors.textSecondary)
                    }
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
        .contextMenu {
            if let localURL = downloadManager.localURL(for: track) {
                ShareLink(item: localURL,
                          preview: SharePreview(track.title, image: Image(systemName: "music.note"))) {
                    Label("Поделиться файлом", systemImage: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) {
                favoritesManager.remove(track)
            } label: {
                Label("Убрать из избранного", systemImage: "heart.slash")
            }
        }
    }

    private var statusGlyph: some View {
        ZStack {
            Circle()
                .fill(AppColors.accentTinted)
                .frame(width: 38, height: 38)
                .overlay {
                    Circle().strokeBorder(AppColors.accentAdaptive.opacity(0.4), lineWidth: 1)
                }

            if isPlaying {
                MiniEqualizerView(isPlaying: true, maxHeight: 14)
            } else {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive)
            }
        }
    }

    private var actionsCluster: some View {
        HStack(spacing: 14) {
            downloadGlyph

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

            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppGradients.accentGradient))
                .shadow(color: AppColors.accent.opacity(0.3), radius: 6, y: 2)
        }
    }

    @ViewBuilder
    private var downloadGlyph: some View {
        if isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.success)
                .frame(width: 32, height: 32)
        } else if let state = downloadManager.downloads[track.url] {
            switch state {
            case .downloading(let progress):
                CircularProgressView(progress: progress)
                    .frame(width: 18, height: 18)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.lightImpact()
                        downloadManager.cancelDownload(track)
                    }
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.success)
                    .frame(width: 32, height: 32)
            case .failed:
                Button {
                    HapticManager.lightImpact()
                    downloadManager.download(track)
                } label: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.error)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button {
                HapticManager.lightImpact()
                downloadManager.download(track)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func play() {
        HapticManager.mediumImpact()
        if isPlaying {
            radioPlayer.toggleFilePause()
        } else {
            let localURL = downloadManager.localURL(for: track)
            radioPlayer.playFile(track, localURL: localURL, queue: favoritesManager.favorites)
        }
    }
}
