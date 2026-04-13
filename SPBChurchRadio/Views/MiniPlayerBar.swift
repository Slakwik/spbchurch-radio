import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNowPlaying = false

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 0) {
                // Progress line with accent color
                GeometryReader { geo in
                    let progress = radioPlayer.filePlayer.duration > 0
                        ? radioPlayer.filePlayer.currentTime / radioPlayer.filePlayer.duration
                        : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.textSecondary.opacity(0.1))
                            .frame(height: 3)
                        Capsule()
                            .fill(AppGradients.accentGradient)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)

                HStack(spacing: isIPad ? 14 : 10) {
                    // Artwork thumbnail — tap opens Now Playing
                    Button(action: {
                        HapticManager.lightImpact()
                        showNowPlaying = true
                    }) {
                        ZStack {
                            ArtworkView(url: track.url, size: isIPad ? 42 : 36, cornerRadius: 8)

                            if radioPlayer.isFilePlaying {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppColors.background.opacity(0.4))
                                    .frame(width: isIPad ? 42 : 36, height: isIPad ? 42 : 36)

                                MiniEqualizerView(isPlaying: true, barCount: 3, maxHeight: 12)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Title — tap opens Now Playing
                    Button(action: {
                        HapticManager.lightImpact()
                        showNowPlaying = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)

                            Text(radioPlayer.isFilePlaying ? "Воспроизведение" : "На паузе")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(radioPlayer.isFilePlaying ? AppColors.accentAdaptive : AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    // Controls
                    HStack(spacing: isIPad ? 16 : 10) {
                        Button(action: {
                            HapticManager.lightImpact()
                            radioPlayer.playPrevious()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticManager.mediumImpact()
                            radioPlayer.toggleFilePause()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.background)
                                    .frame(width: isIPad ? 38 : 32, height: isIPad ? 38 : 32)
                                    .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 3, x: 2, y: 2)
                                    .shadow(color: AppColors.shadowLight.opacity(0.5), radius: 3, x: -2, y: -2)

                                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: isIPad ? 16 : 13, weight: .semibold))
                                    .foregroundStyle(AppColors.accentAdaptive)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticManager.lightImpact()
                            radioPlayer.playNext()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticManager.lightImpact()
                            withAnimation(.spring(response: 0.3)) {
                                radioPlayer.filePlayer.stop()
                                radioPlayer.activeMode = .none
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: isIPad ? 24 : 20))
                                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, isIPad ? 18 : 14)
                .padding(.vertical, isIPad ? 12 : 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.background)
                    .shadow(color: AppColors.shadowDark, radius: 10, x: 4, y: 4)
                    .shadow(color: AppColors.shadowLight, radius: 10, x: -4, y: -4)
            )
            .fullScreenCover(isPresented: $showNowPlaying) {
                NowPlayingView()
                    .environmentObject(radioPlayer)
            }
        }
    }
}
