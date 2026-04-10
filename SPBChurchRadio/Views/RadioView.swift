import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var animatePulse = false
    @State private var animateRotation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background handled by ContentView
                Color.clear

                VStack(spacing: 0) {
                    Spacer()

                    // Liquid Glass radio orb
                    radioOrb
                        .padding(.bottom, 28)

                    // Station name
                    Text("SPBChurch Radio")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)

                    Text("Интернет-радиостанция")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 28)

                    // Now playing glass card
                    nowPlayingCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 36)

                    // Play button
                    playButton
                        .padding(.bottom, 12)

                    // Status
                    HStack(spacing: 6) {
                        if radioPlayer.isRadioPlaying {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                                .shadow(color: .red.opacity(0.8), radius: 4)
                        }
                        Text(radioPlayer.isRadioPlaying ? "LIVE" : "Нажмите для воспроизведения")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(radioPlayer.isRadioPlaying ? 0.7 : 0.35))
                            .tracking(radioPlayer.isRadioPlaying ? 2 : 0)
                    }

                    Spacer()

                    // File player bar at bottom
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
            .onAppear {
                animatePulse = true
            }
        }
    }

    // MARK: - Radio Orb (Liquid Glass style)

    private var radioOrb: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(radioPlayer.isRadioPlaying ? 0.12 : 0.03),
                                .purple.opacity(radioPlayer.isRadioPlaying ? 0.08 : 0.02)
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

            // Glass orb background
            Circle()
                .fill(
                    .linearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.purple.opacity(0.12),
                            Color.blue.opacity(0.08)
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
                                    .white.opacity(0.35),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .purple.opacity(0.35), radius: 30)
                .shadow(color: .blue.opacity(0.2), radius: 60)

            // Inner highlight (liquid glass reflection)
            Ellipse()
                .fill(
                    .linearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 70, height: 40)
                .offset(y: -22)

            // Icon
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.3), radius: 8)
        }
    }

    // MARK: - Now Playing Card (Glass)

    private var nowPlayingCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                Text("СЕЙЧАС ИГРАЕТ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
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
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            .linearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Play Button (Liquid Glass)

    private var playButton: some View {
        Button(action: { radioPlayer.toggleRadio() }) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        .radialGradient(
                            colors: [
                                .white.opacity(radioPlayer.isRadioPlaying ? 0.15 : 0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 55
                        )
                    )
                    .frame(width: 88, height: 88)

                // Glass button
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                .linearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .purple.opacity(0.2), radius: 16)

                // Icon
                Image(systemName: radioPlayer.isRadioPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
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
                    .fill(.white.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "music.note")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            Text(track.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer()

            Button(action: { radioPlayer.toggleFilePause() }) {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
        )
        .environment(\.colorScheme, .dark)
    }
}
