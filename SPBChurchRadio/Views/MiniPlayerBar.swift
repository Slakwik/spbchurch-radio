import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

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

                HStack(spacing: 12) {
                    // Track icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.accent)
                    }

                    Text(track.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: { radioPlayer.toggleFilePause() }) {
                        Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            radioPlayer.filePlayer.stop()
                            radioPlayer.activeMode = .none
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
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
