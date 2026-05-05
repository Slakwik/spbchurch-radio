import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNowPlaying = false

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 0) {
                // Hairline progress
                GeometryReader { geo in
                    let progress = radioPlayer.filePlayer.duration > 0
                        ? radioPlayer.filePlayer.currentTime / radioPlayer.filePlayer.duration
                        : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.textSecondary.opacity(0.12))
                            .frame(height: 2)
                        Capsule()
                            .fill(AppGradients.accentGradient)
                            .frame(width: geo.size.width * progress, height: 2)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    // Artwork tile + tap to open NowPlaying
                    Button {
                        HapticManager.lightImpact()
                        showNowPlaying = true
                    } label: {
                        ZStack {
                            ArtworkView(url: track.url, size: 40, cornerRadius: 10)

                            if radioPlayer.isFilePlaying {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.black.opacity(0.35))
                                    .frame(width: 40, height: 40)

                                MiniEqualizerView(isPlaying: true, barCount: 3, maxHeight: 12)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Title block — also opens NowPlaying
                    Button {
                        HapticManager.lightImpact()
                        showNowPlaying = true
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(track.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)

                            Text(radioPlayer.isFilePlaying ? "Воспроизведение" : "На паузе")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(radioPlayer.isFilePlaying ? AppColors.accentAdaptive : AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Button {
                            HapticManager.lightImpact()
                            radioPlayer.playPrevious()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticManager.mediumImpact()
                            radioPlayer.toggleFilePause()
                        } label: {
                            Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppGradients.accentGradient))
                                .shadow(color: AppColors.accent.opacity(0.4), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticManager.lightImpact()
                            radioPlayer.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticManager.lightImpact()
                            withAnimation(.spring(response: 0.3)) {
                                radioPlayer.filePlayer.stop()
                                radioPlayer.activeMode = .none
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .auroraGlass(cornerRadius: 18)
            .fullScreenCover(isPresented: $showNowPlaying) {
                NowPlayingView()
                    .environmentObject(radioPlayer)
                    .environmentObject(favoritesManager)
                    .environmentObject(downloadManager)
            }
        }
    }
}
