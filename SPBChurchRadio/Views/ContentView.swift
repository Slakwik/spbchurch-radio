import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RadioView()
                    .tabItem {
                        Image(systemName: "radio")
                        Text("Радио")
                    }
                    .tag(0)

                TrackListView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Треки")
                    }
                    .tag(1)

                DownloadsView()
                    .tabItem {
                        Image(systemName: "arrow.down.circle")
                        Text("Загрузки")
                    }
                    .tag(2)
            }
            .accentColor(Color("AccentColor"))

            // Mini player bar when playing a file and not on radio tab
            if radioPlayer.activeMode == .file,
               radioPlayer.filePlayer.currentTrack != nil,
               selectedTab != 0 {
                MiniPlayerBar()
                    .padding(.bottom, 49) // Above tab bar
            }
        }
    }
}
