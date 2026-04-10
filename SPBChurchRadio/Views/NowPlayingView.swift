import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var vSizeClass

    private var isLandscape: Bool { vSizeClass == .compact }
    private var player: FilePlayerService { radioPlayer.filePlayer }
    private var progress: Double {
        player.duration > 0 ? player.currentTime / player.duration : 0
    }

    var body: some View {
        ZStack {
            // Background: blurred artwork or dark gradient
            backgroundLayer

            if isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(false)
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        VStack(spacing: 0) {
            // Drag handle & close
            header
                .padding(.top, 60)

            Spacer(minLength: 16)

            // Artwork with circular progress
            if let track = player.currentTrack {
                circularArtwork(track: track, artSize: 260, ringSize: 300)
            }

            Spacer(minLength: 20)

            // Track info
            trackInfo
                .padding(.horizontal, 30)

            // Time
            timeRow
                .padding(.horizontal, 30)
                .padding(.top, 12)

            // Controls
            controlButtons
                .padding(.top, 20)

            // Shuffle indicator
            shuffleRow
                .padding(.top, 16)

            Spacer(minLength: 30)
        }
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        HStack(spacing: 24) {
            // Left: artwork
            if let track = player.currentTrack {
                circularArtwork(track: track, artSize: 180, ringSize: 216)
                    .padding(.leading, 40)
            }

            // Right: info + controls
            VStack(spacing: 14) {
                Spacer()
                trackInfo
                timeRow
                controlButtons
                shuffleRow
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 40)
        }
        .padding(.top, 20)
    }

    // MARK: - Components

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Сейчас играет")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
    }

    private func circularArtwork(track: Track, artSize: CGFloat, ringSize: CGFloat) -> some View {
        ZStack {
            // Background ring track
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 4)
                .frame(width: ringSize, height: ringSize)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Artwork
            ArtworkViewDark(url: track.url, size: artSize)
        }
    }

    private var trackInfo: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.title ?? "")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("SPBChurch Radio")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var timeRow: some View {
        HStack {
            Text(formatTime(player.currentTime))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(formatTime(player.duration))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 36) {
            Button(action: { radioPlayer.playPrevious() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button(action: { radioPlayer.toggleFilePause() }) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 64, height: 64)
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 12)

                    Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: radioPlayer.isFilePlaying ? 0 : 2)
                        .contentTransition(.symbolEffect(.replace))
                }
            }

            Button(action: { radioPlayer.playNext() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var shuffleRow: some View {
        Button(action: { player.shuffle.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: "shuffle")
                    .font(.system(size: 13, weight: .semibold))
                Text(player.shuffle ? "Перемешано" : "По порядку")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(player.shuffle ? AppColors.accent : .white.opacity(0.35))
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12)

            if let track = player.currentTrack,
               let img = ArtworkService.shared.cachedArtwork(for: track.url) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 60)
                    .opacity(0.3)
                    .scaleEffect(1.3)
            }

            // Dark overlay
            Color.black.opacity(0.45)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
