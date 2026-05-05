import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigator: AppNavigator
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $navigator.selectedTab) {
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

                FavoritesView()
                    .tabItem {
                        Label("Избранное", systemImage: "heart.fill")
                    }
                    .tag(2)

                DownloadsView()
                    .tabItem {
                        Label("Загрузки", systemImage: "arrow.down.circle.fill")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Настройки", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(AppColors.accentAdaptive)

            // Floating mini player (not on Radio & Settings tabs)
            if radioPlayer.activeMode == .file,
               radioPlayer.filePlayer.currentTrack != nil,
               navigator.selectedTab != 0,
               navigator.selectedTab != 4 {
                MiniPlayerBar()
                    .frame(maxWidth: hSizeClass == .regular ? 600 : .infinity)
                    .padding(.horizontal, hSizeClass == .regular ? 40 : 12)
                    .padding(.bottom, 56)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: radioPlayer.activeMode)
        .onAppear { applyTabBarAppearance() }
        .onChange(of: colorScheme) { _, _ in
            applyTabBarAppearance()
        }
    }

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        appearance.backgroundColor = colorScheme == .dark
            ? UIColor(red: 0.055, green: 0.055, blue: 0.071, alpha: 0.6)
            : UIColor(red: 0.980, green: 0.980, blue: 0.969, alpha: 0.6)
        appearance.shadowColor = colorScheme == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.black.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
