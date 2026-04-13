import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if favoritesManager.favorites.isEmpty {
                    emptyState
                } else {
                    List {
                        // Counter header
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.accentAdaptive)
                            Text("\(favoritesManager.favorites.count) в избранном")
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

                        ForEach(favoritesManager.favorites) { track in
                            FavoriteTrackRow(track: track)
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
                                favoritesManager.remove(favoritesManager.favorites[index])
                            }
                        }
                        .onMove { source, destination in
                            favoritesManager.move(from: source, to: destination)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            EditButton()
                                .foregroundStyle(AppColors.accentAdaptive)
                        }
                    }
                }
            }
            .navigationTitle("Избранное")
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

                Image(systemName: "heart")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AppColors.accentAdaptive.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }

            Text("Нет избранных треков")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Нажмите ♡ на экране плеера,\nчтобы добавить трек сюда")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Favorite Track Row

private struct FavoriteTrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var favoritesManager: FavoritesManager
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
            thumbnail

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: isIPad ? 17 : 15, weight: isCurrentTrack ? .semibold : .regular))
                    .foregroundStyle(isCurrentTrack ? AppColors.accentAdaptive : AppColors.textPrimary.opacity(0.85))
                    .lineLimit(2)

                if isDownloaded {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 9))
                        Text("Загружено")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer(minLength: 4)

            // Unfavorite button
            Button(action: {
                HapticManager.lightImpact()
                favoritesManager.remove(track)
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive)
            }
            .buttonStyle(.plain)

            // Play button
            Button(action: play) {
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

    private var thumbnail: some View {
        let thumbSize: CGFloat = isIPad ? 52 : 46
        let cornerRadius: CGFloat = isIPad ? 12 : 10
        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColors.background)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 4, x: 2, y: 2)
                .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 4, x: -2, y: -2)

            if isCurrentTrack && radioPlayer.isFilePlaying {
                MiniEqualizerView(isPlaying: true, maxHeight: isIPad ? 18 : 14)
            } else {
                Image(systemName: "heart.fill")
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive.opacity(0.5))
            }
        }
    }

    private func play() {
        HapticManager.mediumImpact()
        if isCurrentTrack && radioPlayer.isFilePlaying {
            radioPlayer.toggleFilePause()
        } else {
            let localURL = downloadManager.localURL(for: track)
            radioPlayer.playFile(track, localURL: localURL)
        }
    }
}
