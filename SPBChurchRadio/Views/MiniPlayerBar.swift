import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var showNowPlaying = false

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 0) {
                // Progress line
                GeometryReader { geo in
                    let progress = radioPlayer.filePlayer.duration > 0
                        ? radioPlayer.filePlayer.currentTime / radioPlayer.filePlayer.duration
                        : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.textSecondary.opacity(0.1))
                            .frame(height: 3)
                        Capsule()
                            .fill(AppColors.textPrimary)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)

                HStack(spacing: isIPad ? 14 : 10) {
                    // Artwork thumbnail — tap opens Now Playing
                    Button(action: { showNowPlaying = true }) {
                        ArtworkView(url: track.url, size: isIPad ? 42 : 36, cornerRadius: 8)
                    }
                    .buttonStyle(.plain)

                    // Title — tap opens Now Playing
                    Button(action: { showNowPlaying = true }) {
                        Text(track.title)
                            .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    // Controls
                    HStack(spacing: isIPad ? 16 : 10) {
                        Button(action: { radioPlayer.playPrevious() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button(action: { radioPlayer.toggleFilePause() }) {
                            Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: isIPad ? 18 : 15, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .contentTransition(.symbolEffect(.replace))
                                .frame(width: isIPad ? 38 : 32, height: isIPad ? 38 : 32)
                        }
                        .buttonStyle(.plain)

                        Button(action: { radioPlayer.playNext() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
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
