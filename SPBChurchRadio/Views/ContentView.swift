import SwiftUI

struct ContentView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme
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

                SettingsView()
                    .tabItem {
                        Label("Настройки", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(AppColors.accentAdaptive)

            // Floating mini player (not on Radio & Settings tabs)
            if radioPlayer.activeMode == .file,
               radioPlayer.filePlayer.currentTrack != nil,
               selectedTab != 0,
               selectedTab != 3 {
                MiniPlayerBar()
                    .frame(maxWidth: hSizeClass == .regular ? 600 : .infinity)
                    .padding(.horizontal, hSizeClass == .regular ? 40 : 12)
                    .padding(.bottom, 56)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: radioPlayer.activeMode)
        .onAppear {
            // Custom tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()

            if colorScheme == .dark {
                appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1.0)
            } else {
                appearance.backgroundColor = UIColor(red: 0.941, green: 0.941, blue: 0.953, alpha: 1.0)
            }

            appearance.shadowImage = nil
            appearance.shadowColor = colorScheme == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor(red: 0.659, green: 0.671, blue: 0.710, alpha: 0.3)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: colorScheme) { _, _ in
            // Update tab bar when theme changes
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()

            if colorScheme == .dark {
                appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1.0)
            } else {
                appearance.backgroundColor = UIColor(red: 0.941, green: 0.941, blue: 0.953, alpha: 1.0)
            }

            appearance.shadowImage = nil
            appearance.shadowColor = colorScheme == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor(red: 0.659, green: 0.671, blue: 0.710, alpha: 0.3)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
