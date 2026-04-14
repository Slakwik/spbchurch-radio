import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNowPlaying = false
    @State private var pulseScale: CGFloat = 1.0

    private var isLandscape: Bool { vSizeClass == .compact }
    private var isIPad: Bool { hSizeClass == .regular && vSizeClass == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showNowPlaying) {
                NowPlayingView()
                    .environmentObject(radioPlayer)
                    .environmentObject(favoritesManager)
                    .environmentObject(downloadManager)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            stationHeader
                .padding(.top, isIPad ? 20 : 12)
                .padding(.horizontal, 20)

            Spacer(minLength: 14)

            // Play/stop button
            playStopButton
                .padding(.bottom, isIPad ? 28 : 20)

            // Glowing tree
            glowingTree
                .padding(.horizontal, 30)

            Spacer(minLength: 18)

            // Track info + find button
            trackInfo
                .padding(.horizontal, 24)

            Spacer(minLength: 12)

            // Live / file widget
            bottomStatus
                .padding(.horizontal, 24)
                .padding(.bottom, isIPad ? 30 : 20)
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 20) {
            // Left: tree + play
            VStack(spacing: 14) {
                Spacer()
                playStopButton
                glowingTree
                    .frame(maxWidth: 200)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right: info + status
            VStack(spacing: 14) {
                Spacer()
                stationHeader
                trackInfo
                bottomStatus
                    .frame(maxWidth: 360)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Station Header

    private var stationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Радио")
                    .font(.system(size: isIPad ? 36 : 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("SPBChurch")
                    .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive)
            }
            Spacer()

            // Equalizer in header when playing
            if radioPlayer.isRadioPlaying {
                LargeEqualizerView(isPlaying: true)
                    .frame(height: 36)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Glowing Tree

    private var glowingTree: some View {
        let treeSize: CGFloat = isIPad ? 320 : isLandscape ? 180 : 260
        let isPlaying = radioPlayer.isRadioPlaying

        return ZStack {
            // Outer radial glow — visible only when playing
            if isPlaying {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.accentAdaptive.opacity(0.55),
                                AppColors.accentAdaptive.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: treeSize * 0.15,
                            endRadius: treeSize * 0.75
                        )
                    )
                    .frame(width: treeSize * 1.4, height: treeSize * 1.4)
                    .blur(radius: 20)
                    .scaleEffect(pulseScale)
                    .transition(.opacity)
            }

            // Tree image
            Image("TreeBackground")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: treeSize, height: treeSize)
                .shadow(color: isPlaying ? AppColors.accentAdaptive.opacity(0.7) : .clear, radius: 30)
                .shadow(color: isPlaying ? AppColors.accentAdaptive.opacity(0.4) : .clear, radius: 60)
                .animation(.easeInOut(duration: 1.2), value: isPlaying)
        }
        .onAppear {
            if radioPlayer.isRadioPlaying { startPulsing() }
        }
        .onChange(of: radioPlayer.isRadioPlaying) { _, playing in
            if playing { startPulsing() } else { pulseScale = 1.0 }
        }
    }

    private func startPulsing() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    // MARK: - Play / Stop Button

    private var playStopButton: some View {
        let size: CGFloat = isIPad ? 108 : 96
        let isPlaying = radioPlayer.isRadioPlaying

        return Button(action: {
            HapticManager.mediumImpact()
            radioPlayer.toggleRadio()
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: size, height: size)
                    .shadow(color: AppColors.shadowDark, radius: 12, x: 7, y: 7)
                    .shadow(color: AppColors.shadowLight, radius: 12, x: -7, y: -7)

                // Gold outline — always visible, brighter when playing
                Circle()
                    .stroke(
                        AppColors.accentAdaptive.opacity(isPlaying ? 0.7 : 0.35),
                        lineWidth: 2
                    )
                    .frame(width: size - 10, height: size - 10)
                    .animation(.easeInOut(duration: 0.3), value: isPlaying)

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: isIPad ? 40 : 34, weight: .medium))
                    .foregroundStyle(isPlaying ? AppColors.accentAdaptive : AppColors.textPrimary)
                    .frame(width: size, height: size)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(NeumorphicButtonStyle())
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(radioPlayer.currentRadioTrack)
                .font(.system(size: isIPad ? 20 : 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("SPBChurch Radio")
                .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            if RadioTitle.isSearchable(radioPlayer.currentRadioTrack) {
                findTrackButton
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Find Track Button

    private var findTrackButton: some View {
        Button(action: findCurrentTrackInLibrary) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                Text("Найти в библиотеке")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(AppColors.accentAdaptive)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(NeumorphicButtonStyle())
        .neumorphicRaised(cornerRadius: 20)
    }

    private func findCurrentTrackInLibrary() {
        let query = RadioTitle.cleaned(radioPlayer.currentRadioTrack)
        guard !query.isEmpty else { return }
        HapticManager.mediumImpact()
        trackListVM.searchText = query
        navigator.go(to: .tracks)
    }

    // MARK: - Bottom Status (live indicator + file player shortcut)

    private var bottomStatus: some View {
        VStack(spacing: 12) {
            liveIndicatorRow

            if radioPlayer.activeMode == .file,
               radioPlayer.filePlayer.currentTrack != nil {
                filePlayerRow
            }
        }
    }

    private var liveIndicatorRow: some View {
        HStack(spacing: 10) {
            if radioPlayer.isRadioPlaying {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)
                    .shadow(color: AppColors.success.opacity(0.5), radius: 4)
            } else {
                Circle()
                    .fill(AppColors.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }

            Text(radioPlayer.isRadioPlaying ? "В ЭФИРЕ" : "ОФЛАЙН")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(radioPlayer.isRadioPlaying ? AppColors.accentAdaptive : AppColors.textSecondary)
                .tracking(2)

            if radioPlayer.isRadioPlaying {
                Spacer()
                MiniEqualizerView(isPlaying: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .neumorphicRaised(cornerRadius: 14)
    }

    @ViewBuilder
    private var filePlayerRow: some View {
        if let track = radioPlayer.filePlayer.currentTrack {
            Button(action: {
                HapticManager.lightImpact()
                showNowPlaying = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accentAdaptive)

                    Text(track.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(NeumorphicButtonStyle())
            .neumorphicRaised(cornerRadius: 14)
        }
    }
}

// MARK: - Neumorphic Button Style

struct NeumorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style (compatibility)

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - File Now Playing Bar (neumorphic)

struct FileNowPlayingBar: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.accentAdaptive)

            Text(track.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()

            Button(action: {
                HapticManager.selection()
                radioPlayer.filePlayer.shuffle.toggle()
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(radioPlayer.filePlayer.shuffle ? AppColors.accentAdaptive : AppColors.textSecondary.opacity(0.3))
            }

            Button(action: {
                HapticManager.lightImpact()
                radioPlayer.playPrevious()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
            }

            Button(action: {
                HapticManager.mediumImpact()
                radioPlayer.toggleFilePause()
            }) {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            Button(action: {
                HapticManager.lightImpact()
                radioPlayer.playNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .neumorphicRaised(cornerRadius: 14)
    }
}
