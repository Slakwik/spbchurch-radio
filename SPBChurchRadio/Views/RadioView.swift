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
        ZStack {
            AppColors.background.ignoresSafeArea()

            // Tree as full-screen background — scaled to fill, clipped to bounds
            treeBackground

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView()
                .environmentObject(radioPlayer)
                .environmentObject(favoritesManager)
                .environmentObject(downloadManager)
        }
        .onAppear {
            if radioPlayer.isRadioPlaying { startPulsing() }
        }
        .onChange(of: radioPlayer.isRadioPlaying) { _, playing in
            if playing { startPulsing() } else { pulseScale = 1.0 }
        }
    }

    // MARK: - Tree Background

    private var treeBackground: some View {
        let isPlaying = radioPlayer.isRadioPlaying
        return ZStack {
            Image("TreeBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(isPlaying ? 0.75 : 0.20)
                .animation(.easeInOut(duration: 1.2), value: isPlaying)

            // Gold halo — appears only when playing
            RadialGradient(
                colors: [
                    AppColors.accentAdaptive.opacity(isPlaying ? 0.35 : 0),
                    AppColors.accentAdaptive.opacity(isPlaying ? 0.08 : 0),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 480
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .scaleEffect(pulseScale)
            .animation(.easeInOut(duration: 1.2), value: isPlaying)
        }
        .ignoresSafeArea()
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            stationHeader
                .padding(.top, isIPad ? 20 : 12)

            Spacer(minLength: 20)

            // Play/stop button — vertically centered, stable position
            playStopButton

            Spacer(minLength: 20)

            // Track info + find button (fixed-height container)
            trackInfo
                .padding(.bottom, 14)

            // Live / file widget
            bottomStatus
                .padding(.bottom, isIPad ? 20 : 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isIPad ? 28 : 20)
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 20) {
            // Left: play button
            VStack {
                Spacer()
                playStopButton
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Station Header

    private var stationHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Радио")
                    .font(.system(size: isIPad ? 36 : 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("SPBChurch")
                    .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                    .foregroundStyle(AppColors.accentAdaptive)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            // Equalizer in header when playing
            if radioPlayer.isRadioPlaying {
                LargeEqualizerView(isPlaying: true)
                    .frame(height: 32)
                    .layoutPriority(0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func startPulsing() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    // MARK: - Play / Stop Button

    private var playStopButton: some View {
        let size: CGFloat = isIPad ? 162 : 144
        let isPlaying = radioPlayer.isRadioPlaying

        return Button(action: {
            HapticManager.mediumImpact()
            radioPlayer.toggleRadio()
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: size, height: size)
                    .shadow(color: AppColors.shadowDark, radius: 16, x: 9, y: 9)
                    .shadow(color: AppColors.shadowLight, radius: 16, x: -9, y: -9)

                // Gold outline — always visible, brighter when playing
                Circle()
                    .stroke(
                        AppColors.accentAdaptive.opacity(isPlaying ? 0.7 : 0.35),
                        lineWidth: 2.5
                    )
                    .frame(width: size - 14, height: size - 14)
                    .animation(.easeInOut(duration: 0.3), value: isPlaying)

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: isIPad ? 60 : 52, weight: .medium))
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
                .frame(height: isIPad ? 52 : 46) // fixed height for 1-2 lines

            Text("SPBChurch Radio")
                .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            // Always reserve the space so the layout doesn't jump
            findTrackButton
                .padding(.top, 4)
                .opacity(RadioTitle.isSearchable(radioPlayer.currentRadioTrack) ? 1 : 0)
                .allowsHitTesting(RadioTitle.isSearchable(radioPlayer.currentRadioTrack))
                .animation(.easeInOut(duration: 0.25), value: radioPlayer.currentRadioTrack)
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
