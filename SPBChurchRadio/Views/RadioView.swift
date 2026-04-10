import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var animatePulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep navy gradient background
                radioBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Radio orb with gold accents
                    radioOrb
                        .padding(.bottom, 28)

                    // Station name
                    Text("SPBChurch Radio")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.bottom, 4)

                    Text("Церковь «Преображение»")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 28)

                    // Now playing card
                    nowPlayingCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 36)

                    // Play button
                    playButton
                        .padding(.bottom, 12)

                    // Live status
                    HStack(spacing: 6) {
                        if radioPlayer.isRadioPlaying {
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 7, height: 7)
                                .shadow(color: AppColors.accent.opacity(0.7), radius: 5)
                        }
                        Text(radioPlayer.isRadioPlaying ? "В ЭФИРЕ" : "Нажмите для воспроизведения")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(radioPlayer.isRadioPlaying ? 0.7 : 0.35))
                            .tracking(radioPlayer.isRadioPlaying ? 2.5 : 0)
                    }

                    Spacer()

                    // File player bar
                    if radioPlayer.activeMode == .file,
                       let track = radioPlayer.filePlayer.currentTrack {
                        FileNowPlayingBar(track: track)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { animatePulse = true }
        }
    }

    // MARK: - Background

    private var radioBackground: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(red: 0.04, green: 0.08, blue: 0.18),
                        Color(red: 0.06, green: 0.10, blue: 0.22),
                        Color(red: 0.04, green: 0.07, blue: 0.16),

                        Color(red: 0.07, green: 0.12, blue: 0.26),
                        Color(red: 0.10, green: 0.16, blue: 0.32),
                        Color(red: 0.06, green: 0.10, blue: 0.22),

                        Color(red: 0.05, green: 0.09, blue: 0.20),
                        Color(red: 0.08, green: 0.13, blue: 0.28),
                        Color(red: 0.04, green: 0.08, blue: 0.18)
                    ]
                )
            } else {
                LinearGradient(
                    colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                        AppColors.primary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Radio Orb

    private var radioOrb: some View {
        ZStack {
            // Pulse rings with gold tint
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(radioPlayer.isRadioPlaying ? 0.18 : 0.04),
                                AppColors.accentLight.opacity(radioPlayer.isRadioPlaying ? 0.08 : 0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: CGFloat(130 + i * 44),
                        height: CGFloat(130 + i * 44)
                    )
                    .scaleEffect(animatePulse && radioPlayer.isRadioPlaying ? 1.08 : 1.0)
                    .opacity(animatePulse && radioPlayer.isRadioPlaying ? 0.6 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2 + Double(i) * 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animatePulse && radioPlayer.isRadioPlaying
                    )
            }

            // Glass orb with gold gradient
            Circle()
                .fill(
                    .linearGradient(
                        colors: [
                            AppColors.accent.opacity(0.25),
                            AppColors.accentLight.opacity(0.12),
                            AppColors.primaryLight.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .overlay(
                    Circle()
                        .stroke(
                            .linearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.5),
                                    AppColors.accentLight.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppColors.accent.opacity(0.25), radius: 30)
                .shadow(color: AppColors.primaryLight.opacity(0.3), radius: 50)

            // Inner glass reflection
            Ellipse()
                .fill(
                    .linearGradient(
                        colors: [.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 70, height: 40)
                .offset(y: -22)

            // Cross icon
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppColors.accent.opacity(0.4), radius: 8)
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
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            .linearGradient(
                                colors: [AppColors.accent.opacity(0.25), AppColors.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button(action: { radioPlayer.toggleRadio() }) {
            ZStack {
                // Gold glow
                Circle()
                    .fill(
                        .radialGradient(
                            colors: [
                                AppColors.accent.opacity(radioPlayer.isRadioPlaying ? 0.2 : 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 28,
                            endRadius: 55
                        )
                    )
                    .frame(width: 88, height: 88)

                // Glass button with gold border
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                .linearGradient(
                                    colors: [AppColors.accent.opacity(0.6), AppColors.accentLight.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppColors.accent.opacity(0.2), radius: 16)

                // Icon
                Image(systemName: radioPlayer.isRadioPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .offset(x: radioPlayer.isRadioPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .environment(\.colorScheme, .dark)
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

            Button(action: { radioPlayer.toggleFilePause() }) {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
        .environment(\.colorScheme, .dark)
    }
}
