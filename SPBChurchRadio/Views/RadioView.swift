import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var animatePulse = false
    @State private var treeGlow = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark base
                Color(red: 0.03, green: 0.05, blue: 0.12).ignoresSafeArea()

                // Tree background — pre-processed dark image, fill screen
                Image("TreeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(radioPlayer.isRadioPlaying ? 0.9 : 0.55)
                    .shadow(color: AppColors.accent.opacity(treeGlow ? 0.2 : 0.05), radius: 50)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: treeGlow)
                    .ignoresSafeArea()

                // Subtle gradient for text readability at top/bottom
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)

                    Spacer()

                    LinearGradient(
                        colors: [.clear, Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                }
                .ignoresSafeArea()

                // Pulsing rings behind tree (centered on image)
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.accent.opacity(radioPlayer.isRadioPlaying ? 0.12 : 0.03),
                                        AppColors.accentLight.opacity(radioPlayer.isRadioPlaying ? 0.06 : 0.01)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .frame(
                                width: CGFloat(200 + i * 60),
                                height: CGFloat(200 + i * 60)
                            )
                            .scaleEffect(animatePulse && radioPlayer.isRadioPlaying ? 1.06 : 1.0)
                            .opacity(animatePulse && radioPlayer.isRadioPlaying ? 0.5 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5 + Double(i) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: animatePulse && radioPlayer.isRadioPlaying
                            )
                    }
                }
                .offset(y: -30)

                // Content
                VStack(spacing: 0) {
                    // Top: station name
                    VStack(spacing: 4) {
                        Text("SPBChurch Radio")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Церковь «Преображение»")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.top, 60)

                    Spacer()

                    // Bottom controls
                    VStack(spacing: 20) {
                        // Now playing card
                        nowPlayingCard

                        // Play button
                        playButton

                        // Live status
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
                    .padding(.horizontal, 24)

                    // File player bar
                    if radioPlayer.activeMode == .file,
                       let track = radioPlayer.filePlayer.currentTrack {
                        FileNowPlayingBar(track: track)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    Spacer()
                        .frame(height: 20)
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                animatePulse = true
                treeGlow = true
            }
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
                .fill(.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            .linearGradient(
                                colors: [AppColors.accent.opacity(0.2), AppColors.accent.opacity(0.05)],
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
                                AppColors.accent.opacity(radioPlayer.isRadioPlaying ? 0.25 : 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 25,
                            endRadius: 52
                        )
                    )
                    .frame(width: 84, height: 84)

                // Glass button
                Circle()
                    .fill(.black.opacity(0.3))
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
                    .clipShape(Circle())
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
                    .font(.system(size: 26, weight: .medium))
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
                .fill(.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
        .environment(\.colorScheme, .dark)
    }
}
