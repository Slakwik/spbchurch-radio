import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    let progress = radioPlayer.filePlayer.duration > 0
                        ? radioPlayer.filePlayer.currentTime / radioPlayer.filePlayer.duration
                        : 0
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress)
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .foregroundColor(.accentColor)
                        .frame(width: 30)

                    Text(track.title)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    Button(action: { radioPlayer.toggleFilePause() }) {
                        Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    Button(action: { radioPlayer.filePlayer.stop(); radioPlayer.activeMode = .none }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
        }
    }
}
