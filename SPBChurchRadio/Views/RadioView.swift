import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    @State private var animateWave = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.08, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Radio visualization
                    ZStack {
                        // Animated circles
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(
                                    Color.white.opacity(radioPlayer.isRadioPlaying ? 0.15 : 0.05),
                                    lineWidth: 2
                                )
                                .frame(
                                    width: CGFloat(120 + i * 50),
                                    height: CGFloat(120 + i * 50)
                                )
                                .scaleEffect(animateWave && radioPlayer.isRadioPlaying ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: Double(i) * 0.3 + 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                    value: animateWave
                                )
                        }

                        // Center icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.3, blue: 0.9),
                                        Color(red: 0.6, green: 0.3, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .purple.opacity(0.5), radius: 20)

                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }

                    // Station name
                    Text("SPBChurch Radio")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Current track
                    VStack(spacing: 8) {
                        Text("Сейчас играет")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)

                        Text(radioPlayer.currentRadioTrack)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)

                    Spacer()

                    // Play/Stop button
                    Button(action: {
                        radioPlayer.toggleRadio()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: radioPlayer.isRadioPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }

                    // Status text
                    Text(radioPlayer.isRadioPlaying ? "В эфире" : "Нажмите для воспроизведения")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    // File player bar
                    if radioPlayer.activeMode == .file,
                       let track = radioPlayer.filePlayer.currentTrack {
                        FileNowPlayingBar(track: track)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                animateWave = true
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct FileNowPlayingBar: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .foregroundColor(.white)

            Text(track.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button(action: { radioPlayer.toggleFilePause() }) {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .cornerRadius(10)
    }
}
