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
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
        }
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)

            // Dotted artwork ring with progress
            if let track = player.currentTrack {
                dottedProgressArtwork(track: track, artSize: 220, ringSize: 270)
            }

            // Track info
            trackInfo
                .padding(.top, 20)

            Spacer(minLength: 16)

            // Bottom controls
            bottomControls
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        HStack(spacing: 24) {
            Spacer()

            if let track = player.currentTrack {
                dottedProgressArtwork(track: track, artSize: 140, ringSize: 175)
            }

            VStack(spacing: 12) {
                Spacer()
                trackInfo
                bottomControls
                    .frame(maxWidth: 320)
                Spacer()
            }

            Spacer()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Музыка")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, isLandscape ? 8 : 12)
    }

    // MARK: - Dotted Progress Artwork

    private func dottedProgressArtwork(track: Track, artSize: CGFloat, ringSize: CGFloat) -> some View {
        let dotCount = 36

        return ZStack {
            // Dotted ring — filled portion shows progress
            ForEach(0..<dotCount, id: \.self) { i in
                let angle = Double(i) / Double(dotCount) * 360.0
                let normalizedPos = Double(i) / Double(dotCount)
                let isFilled = normalizedPos <= progress
                let dotSize: CGFloat = i % 4 == 0 ? 7 : 4.5

                Circle()
                    .fill(isFilled ? AppColors.textPrimary : AppColors.textSecondary.opacity(0.15))
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -ringSize / 2)
                    .rotationEffect(.degrees(angle - 90))
                    .animation(.linear(duration: 0.3), value: progress)
            }

            // Frosted artwork
            ArtworkViewFrosted(url: track.url, size: artSize)
                .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 20, x: 10, y: 10)
                .shadow(color: AppColors.shadowLight, radius: 20, x: -10, y: -10)
        }
        .frame(width: ringSize + 20, height: ringSize + 20)
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(player.currentTrack?.title ?? "")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("SPBChurch Radio")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 14) {
            // Speed widget
            VStack(spacing: 12) {
                // Shuffle toggle
                Button(action: { player.shuffle.toggle() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(player.shuffle ? AppColors.textPrimary : AppColors.textSecondary.opacity(0.4))
                        Text(player.shuffle ? "Микс" : "x1")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .neumorphicRaised(cornerRadius: 16)

                // Time display
                VStack(spacing: 2) {
                    Text(formatTime(player.currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(formatTime(player.duration))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .neumorphicRaised(cornerRadius: 16)
            }
            .frame(maxWidth: .infinity)

            // Click wheel
            clickWheel
        }
    }

    // MARK: - Click Wheel

    private var clickWheel: some View {
        let wheelSize: CGFloat = 150
        let centerSize: CGFloat = 52

        return ZStack {
            Circle()
                .fill(AppColors.background)
                .frame(width: wheelSize, height: wheelSize)
                .shadow(color: AppColors.shadowDark, radius: 10, x: 6, y: 6)
                .shadow(color: AppColors.shadowLight, radius: 10, x: -6, y: -6)

            // Menu dots (top)
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    ForEach(0..<2, id: \.self) { _ in
                        Circle().fill(AppColors.textPrimary.opacity(0.4))
                            .frame(width: 4, height: 4)
                    }
                }
                HStack(spacing: 3) {
                    ForEach(0..<2, id: \.self) { _ in
                        Circle().fill(AppColors.textPrimary.opacity(0.4))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .offset(y: -wheelSize * 0.28)

            // Rewind (left)
            Button(action: { radioPlayer.playPrevious() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
            .offset(x: -wheelSize * 0.28)

            // Forward (right)
            Button(action: { radioPlayer.playNext() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
            .offset(x: wheelSize * 0.28)

            // Pause (bottom)
            Image(systemName: "pause.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textPrimary.opacity(0.4))
                .offset(y: wheelSize * 0.28)

            // Center button
            Button(action: { radioPlayer.toggleFilePause() }) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: centerSize, height: centerSize)
                        .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 4, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.8), radius: 4, x: -2, y: -2)

                    Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .offset(x: radioPlayer.isFilePlaying ? 0 : 2)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(NeumorphicButtonStyle())

            // Decorative dots
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(AppColors.textSecondary.opacity(0.15))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            .offset(x: wheelSize * 0.42, y: wheelSize * 0.42)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
