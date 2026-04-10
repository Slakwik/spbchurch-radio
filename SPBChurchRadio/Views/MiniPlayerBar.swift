import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass

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
                            .fill(AppColors.textSecondary.opacity(0.15))
                            .frame(height: 3)
                        Capsule()
                            .fill(AppColors.accent)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)

                HStack(spacing: isIPad ? 14 : 10) {
                    // Track icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.accent.opacity(0.12))
                            .frame(width: isIPad ? 42 : 36, height: isIPad ? 42 : 36)
                        Image(systemName: "music.note")
                            .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                            .foregroundStyle(AppColors.accent)
                    }

                    // Title
                    Text(track.title)
                        .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Controls
                    HStack(spacing: isIPad ? 16 : 10) {
                        Button(action: {
                            radioPlayer.filePlayer.shuffle.toggle()
                        }) {
                            Image(systemName: "shuffle")
                                .font(.system(size: isIPad ? 15 : 13, weight: .semibold))
                                .foregroundStyle(radioPlayer.filePlayer.shuffle ? AppColors.accent : AppColors.textSecondary.opacity(0.4))
                        }
                        .buttonStyle(.plain)

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
                    .fill(.ultraThinMaterial)
                    .shadow(color: AppColors.primary.opacity(0.08), radius: 12, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColors.accent.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
    }
}
