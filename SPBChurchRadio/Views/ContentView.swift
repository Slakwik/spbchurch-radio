import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background that adapts to mode
            Group {
                if selectedTab == 0 {
                    MeshGradientBackground()
                } else {
                    Color(.systemGroupedBackground)
                }
            }
            .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                RadioView()
                    .tabItem {
                        Label("Радио", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .tag(0)

                TrackListView()
                    .tabItem {
                        Label("Треки", systemImage: "music.note.list")
                    }
                    .tag(1)

                DownloadsView()
                    .tabItem {
                        Label("Загрузки", systemImage: "arrow.down.circle.fill")
                    }
                    .tag(2)
            }
            .tint(.white)

            // Floating mini player
            if radioPlayer.activeMode == .file,
               radioPlayer.filePlayer.currentTrack != nil,
               selectedTab != 0 {
                MiniPlayerBar()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 56)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: radioPlayer.activeMode)
    }
}

// MARK: - iOS 26 Mesh Gradient Background

struct MeshGradientBackground: View {
    @State private var animate = false

    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [animate ? 0.6 : 0.4, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.08, green: 0.04, blue: 0.20),
                    Color(red: 0.04, green: 0.02, blue: 0.12),

                    Color(red: 0.06, green: 0.03, blue: 0.18),
                    Color(red: 0.15, green: 0.06, blue: 0.35),
                    Color(red: 0.08, green: 0.03, blue: 0.22),

                    Color(red: 0.03, green: 0.02, blue: 0.10),
                    Color(red: 0.10, green: 0.04, blue: 0.25),
                    Color(red: 0.05, green: 0.02, blue: 0.14)
                ]
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.02, blue: 0.10),
                    Color(red: 0.12, green: 0.06, blue: 0.30),
                    Color(red: 0.05, green: 0.03, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
