import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .tint(AppColors.accent)

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
