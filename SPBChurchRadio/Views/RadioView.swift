import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var isLandscape: Bool { vSizeClass == .compact }
    private var isIPad: Bool { hSizeClass == .regular && vSizeClass == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark base
                Color(red: 0.03, green: 0.05, blue: 0.12).ignoresSafeArea()

                // Tree background — static, no animation on image itself
                Image("TreeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(radioPlayer.isRadioPlaying ? 0.8 : 0.5)
                    .animation(.easeInOut(duration: 1.0), value: radioPlayer.isRadioPlaying)

                // Gradient overlays for text readability
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.05, blue: 0.12), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: isLandscape ? 50 : 100)
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: isLandscape ? 100 : 220)
                }
                .ignoresSafeArea()

                // Content
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 16) {
            stationHeader
                .padding(.top, isIPad ? 30 : 16)

            Spacer(minLength: 10)

            // Now playing card
            nowPlayingCard
                .frame(maxWidth: isIPad ? 500 : .infinity)
                .padding(.horizontal, isIPad ? 60 : 24)

            // Play button
            playButton
                .padding(.top, 8)

            // Live status
            liveStatus

            // File player bar
            filePlayerBar

            Spacer(minLength: 0)
                .frame(maxHeight: 20)
        }
        .padding(.horizontal)
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // Left: station info
            VStack(spacing: 12) {
                Spacer()
                stationHeader
                Spacer()
                filePlayerBar
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 20)
            .padding(.bottom, 8)

            // Right: controls
            VStack(spacing: 14) {
                Spacer()
                nowPlayingCard
                    .frame(maxWidth: isIPad ? 450 : 320)
                playButton
                liveStatus
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 20)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    private var stationHeader: some View {
        VStack(spacing: 4) {
            Text("SPBChurch Radio")
                .font(.system(size: isIPad ? 34 : 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Церковь «Преображение»")
                .font(.system(size: isIPad ? 16 : 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var liveStatus: some View {
        HStack(spacing: 6) {
            if radioPlayer.isRadioPlaying {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 7, height: 7)
                    .shadow(color: AppColors.accent.opacity(0.8), radius: 6)
            }
            Text(radioPlayer.isRadioPlaying ? "В ЭФИРЕ" : "Нажмите для воспроизведения")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(radioPlayer.isRadioPlaying ? 0.65 : 0.3))
                .tracking(radioPlayer.isRadioPlaying ? 2.5 : 0)
        }
    }

    @ViewBuilder
    private var filePlayerBar: some View {
        if radioPlayer.activeMode == .file,
           let track = radioPlayer.filePlayer.currentTrack {
            FileNowPlayingBar(track: track)
                .frame(maxWidth: isIPad ? 500 : .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    // MARK: - Now Playing Card

    private var nowPlayingCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.accent.opacity(0.7))
                Text("СЕЙЧАС ИГРАЕТ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.accent.opacity(0.7))
                    .tracking(1.5)
            }

            Text(radioPlayer.currentRadioTrack)
                .font(.system(size: isIPad ? 18 : 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Play Button

    private var playButton: some View {
        let btnSize: CGFloat = isIPad ? 80 : 68
        let outerSize: CGFloat = isIPad ? 100 : 84
        let iconSize: CGFloat = isIPad ? 32 : 26

        return Button(action: { radioPlayer.toggleRadio() }) {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        .radialGradient(
                            colors: [
                                AppColors.accent.opacity(radioPlayer.isRadioPlaying ? 0.25 : 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: btnSize * 0.36,
                            endRadius: outerSize * 0.62
                        )
                    )
                    .frame(width: outerSize, height: outerSize)

                // Button circle
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: btnSize, height: btnSize)
                    .overlay(
                        Circle()
                            .stroke(
                                .linearGradient(
                                    colors: [AppColors.accent.opacity(0.6), AppColors.accentLight.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppColors.accent.opacity(0.15), radius: 14)

                // Icon
                Image(systemName: radioPlayer.isRadioPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .offset(x: radioPlayer.isRadioPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(GlassButtonStyle())
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - File Now Playing Bar

struct FileNowPlayingBar: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "music.note")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.accent)
            }

            Text(track.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer()

            Button(action: { radioPlayer.filePlayer.shuffle.toggle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(radioPlayer.filePlayer.shuffle ? AppColors.accent : .white.opacity(0.3))
            }

            Button(action: { radioPlayer.playPrevious() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            Button(action: { radioPlayer.toggleFilePause() }) {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.accent)
            }

            Button(action: { radioPlayer.playNext() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}
