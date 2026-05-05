import SwiftUI

@main
struct SPBChurchRadioApp: App {
    @StateObject private var radioPlayer = RadioPlayerViewModel()
    @StateObject private var trackListVM = TrackListViewModel()
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var navigator = AppNavigator()
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(radioPlayer)
                .environmentObject(trackListVM)
                .environmentObject(downloadManager)
                .environmentObject(themeManager)
                .environmentObject(navigator)
                .environmentObject(favoritesManager)
                .preferredColorScheme(themeManager.mode.colorScheme)
                .onAppear {
                    radioPlayer.downloadManager = downloadManager
                    LogManager.shared.info("Приложение запущено", source: "App")
                }
                .onReceive(trackListVM.$tracks) { tracks in
                    radioPlayer.allTracks = tracks
                    downloadManager.backfillMetadata(from: tracks)
                }
        }
    }
}
