import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 0) {
                // Thin progress line
                GeometryReader { geo in
                    let progress = radioPlayer.filePlayer.duration > 0
                        ? radioPlayer.filePlayer.currentTime / radioPlayer.filePlayer.duration
                        : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 3)
                        Capsule()
                            .fill(Color.accentColor)
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
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.accentColor)
                    }

                    // Title
                    Text(track.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .lineLimit(1)

                    Spacer()

                    // Play/Pause
                    Button(action: { radioPlayer.toggleFilePause() }) {
                        Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    // Close
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            radioPlayer.filePlayer.stop()
                            radioPlayer.activeMode = .none
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.tertiary)
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
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
}
