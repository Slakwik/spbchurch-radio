import SwiftUI

@main
struct SPBChurchRadioApp: App {
    @StateObject private var radioPlayer = RadioPlayerViewModel()
    @StateObject private var trackListVM = TrackListViewModel()
    @StateObject private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(radioPlayer)
                .environmentObject(trackListVM)
                .environmentObject(downloadManager)
        }
    }
}
