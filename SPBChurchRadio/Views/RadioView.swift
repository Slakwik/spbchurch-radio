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
        Group {
            if isLandscape { landscapeLayout } else { portraitLayout }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundLayer)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView()
                .environmentObject(radioPlayer)
                .environmentObject(favoritesManager)
                .environmentObject(downloadManager)
        }
        .onAppear { if radioPlayer.isRadioPlaying { startPulsing() } }
        .onChange(of: radioPlayer.isRadioPlaying) { _, playing in
            if playing { startPulsing() } else { pulseScale = 1.0 }
        }
    }

    // MARK: - Background (tree image + gold halo)

    private var backgroundLayer: some View {
        let isPlaying = radioPlayer.isRadioPlaying
        return ZStack {
            AppColors.background

            GeometryReader { geo in
                Image("TreeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .opacity(isPlaying ? 0.55 : 0.14)
            .animation(.easeInOut(duration: 1.2), value: isPlaying)

            RadialGradient(
                colors: [
                    AppColors.accentAdaptive.opacity(isPlaying ? 0.30 : 0),
                    AppColors.accentAdaptive.opacity(isPlaying ? 0.08 : 0),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 480
            )
            .blendMode(.plusLighter)
            .scaleEffect(pulseScale)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1.2), value: isPlaying)
        }
        .ignoresSafeArea()
    }

    // MARK: - Portrait

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            stationHeader
                .padding(.top, isIPad ? 16 : 8)

            Spacer()

            playStopButton

            Spacer()

            VStack(spacing: 16) {
                trackInfo
                liveStatusPill
                fileWidget
            }
            .padding(.bottom, isIPad ? 28 : 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isIPad ? 32 : 20)
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: 24) {
            VStack {
                Spacer()
                playStopButton
                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 14) {
                Spacer()
                stationHeader
                trackInfo
                liveStatusPill
                fileWidget
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - Station Header — display typography

    private var stationHeader: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Радио")
                    .font(AppFonts.display(isIPad ? 52 : 44))
                    .tracking(-1)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("SPBChurch")
                    .font(.system(size: isIPad ? 16 : 13, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentAdaptive)
            }

            Spacer(minLength: 0)

            if radioPlayer.isRadioPlaying {
                LargeEqualizerView(isPlaying: true)
                    .frame(height: 28)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Play / Stop button — solid filled accent circle

    private var playStopButton: some View {
        let size: CGFloat = isIPad ? 168 : 144
        let isPlaying = radioPlayer.isRadioPlaying

        return Button {
            HapticManager.mediumImpact()
            radioPlayer.toggleRadio()
        } label: {
            ZStack {
                // Outer breathing ring
                Circle()
                    .strokeBorder(AppColors.accentAdaptive.opacity(isPlaying ? 0.25 : 0), lineWidth: 1.5)
                    .frame(width: size + 28, height: size + 28)
                    .scaleEffect(pulseScale)

                // Main filled circle
                Circle()
                    .fill(
                        isPlaying
                        ? AnyShapeStyle(AppGradients.accentGradient)
                        : AnyShapeStyle(AppColors.surface)
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        Circle().strokeBorder(
                            isPlaying ? Color.white.opacity(0.18) : AppColors.stroke,
                            lineWidth: 1
                        )
                    }
                    .shadow(
                        color: AppColors.accent.opacity(isPlaying ? 0.40 : 0.10),
                        radius: 22, y: 10
                    )

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: isIPad ? 64 : 56, weight: .semibold))
                    .foregroundStyle(isPlaying ? .white : AppColors.accentAdaptive)
                    .frame(width: size, height: size)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: size + 28, height: size + 28)
        }
        .buttonStyle(PressEffectButtonStyle())
    }

    private func startPulsing() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.06
        }
    }

    // MARK: - Track Info — minimalist text block

    private var trackInfo: some View {
        VStack(spacing: 6) {
            Text("СЕЙЧАС ИГРАЕТ")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(AppColors.textSecondary)

            Text(radioPlayer.currentRadioTrack)
                .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: isIPad ? 56 : 50)

            if RadioTitle.isSearchable(radioPlayer.currentRadioTrack) {
                Button(action: findCurrentTrackInLibrary) {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Найти в библиотеке")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .auroraTonalPill()
                }
                .buttonStyle(PressEffectButtonStyle())
            } else {
                Color.clear.frame(height: 32)
            }
        }
    }

    private func findCurrentTrackInLibrary() {
        let query = RadioTitle.cleaned(radioPlayer.currentRadioTrack)
        guard !query.isEmpty else { return }
        HapticManager.mediumImpact()
        trackListVM.searchText = query
        navigator.go(to: .tracks)
    }

    // MARK: - Live Status — small inline pill

    private var liveStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(radioPlayer.isRadioPlaying ? AppColors.success : AppColors.textSecondary.opacity(0.4))
                .frame(width: 6, height: 6)
                .shadow(color: AppColors.success.opacity(radioPlayer.isRadioPlaying ? 0.5 : 0), radius: 4)

            Text(radioPlayer.isRadioPlaying ? "В ЭФИРЕ" : "ОФЛАЙН")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(radioPlayer.isRadioPlaying ? AppColors.textPrimary : AppColors.textSecondary)
        }
    }

    // MARK: - File player widget — appears only when a file is queued

    @ViewBuilder
    private var fileWidget: some View {
        if radioPlayer.activeMode == .file,
           let track = radioPlayer.filePlayer.currentTrack {
            Button {
                HapticManager.lightImpact()
                showNowPlaying = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.accentAdaptive)
                        .frame(width: 32, height: 32)
                        .background {
                            Circle().fill(AppColors.accentTinted)
                        }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Играет файл")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressEffectButtonStyle())
            .auroraGlass(cornerRadius: 18)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Press feedback button style — replaces the heavier neumorphic style

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Compatibility — earlier views referenced these names.
typealias NeumorphicButtonStyle = PressEffectButtonStyle
typealias GlassButtonStyle = PressEffectButtonStyle

// MARK: - File now-playing bar (compatibility — used elsewhere)

struct FileNowPlayingBar: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.accentAdaptive)

            Text(track.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                HapticManager.selection()
                radioPlayer.filePlayer.order = radioPlayer.filePlayer.order.next
            } label: {
                Image(systemName: radioPlayer.filePlayer.order.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.accentAdaptive)
                    .contentTransition(.symbolEffect(.replace))
            }

            Button { radioPlayer.playPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.6))
            }

            Button { radioPlayer.toggleFilePause() } label: {
                Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Button { radioPlayer.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .auroraGlass(cornerRadius: 14)
    }
}
