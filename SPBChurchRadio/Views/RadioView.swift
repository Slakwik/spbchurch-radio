import SwiftUI

struct RadioView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

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
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Header
            stationHeader
                .padding(.top, isIPad ? 20 : 12)

            Spacer(minLength: 10)

            // Artwork with dotted progress ring
            dottedArtworkRing
                .padding(.horizontal, 30)

            // Track info
            trackInfo
                .padding(.top, 16)

            Spacer(minLength: 10)

            // Bottom controls grid
            controlsGrid
                .padding(.horizontal, 20)
                .padding(.bottom, isIPad ? 30 : 16)
        }
        .padding(.horizontal)
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 20) {
            // Left: artwork + info
            VStack(spacing: 12) {
                Spacer()
                dottedArtworkRing
                    .frame(maxWidth: 200)
                trackInfo
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right: controls
            VStack(spacing: 14) {
                Spacer()
                stationHeader
                controlsGrid
                    .frame(maxWidth: 320)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Station Header

    private var stationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Радио")
                    .font(.system(size: isIPad ? 36 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("SPBChurch")
                    .font(.system(size: isIPad ? 14 : 12, weight: .medium, design: .rounded))
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

    // MARK: - Dotted Artwork Ring

    private var dottedArtworkRing: some View {
        let artSize: CGFloat = isIPad ? 280 : isLandscape ? 160 : 220
        let ringSize: CGFloat = artSize + 50
        let dotCount = 36
        let isPlaying = radioPlayer.isRadioPlaying

        return ZStack {
            // Dotted ring — accent-colored when playing
            ForEach(0..<dotCount, id: \.self) { i in
                let angle = Double(i) / Double(dotCount) * 360.0
                let dotSize: CGFloat = i % 4 == 0 ? 6 : 4

                Circle()
                    .fill(
                        isPlaying
                        ? AppColors.accentAdaptive.opacity(i % 4 == 0 ? 0.7 : 0.4)
                        : AppColors.textPrimary.opacity(0.15)
                    )
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -ringSize / 2)
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut(duration: 0.6), value: isPlaying)
            }

            // Frosted glass artwork circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.9),
                                AppColors.background.opacity(colorScheme == .dark ? 0.8 : 0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: artSize * 0.5
                        )
                    )
                    .frame(width: artSize, height: artSize)

                // Tree image or icon
                Image("TreeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: artSize * 0.7, height: artSize * 0.7)
                    .clipShape(Circle())
                    .blur(radius: 3)
                    .opacity(isPlaying ? 0.7 : 0.4)
                    .animation(.easeInOut(duration: 1.0), value: isPlaying)

                // Gold ring border when playing
                if isPlaying {
                    Circle()
                        .stroke(AppColors.accentAdaptive.opacity(0.3), lineWidth: 2)
                        .frame(width: artSize - 4, height: artSize - 4)
                        .transition(.opacity)
                }
            }
            .shadow(color: AppColors.shadowDark.opacity(0.3), radius: 20, x: 10, y: 10)
            .shadow(color: AppColors.shadowLight, radius: 20, x: -10, y: -10)
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(radioPlayer.currentRadioTrack)
                .font(.system(size: isIPad ? 20 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("SPBChurch Radio")
                .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Controls Grid

    private var controlsGrid: some View {
        HStack(spacing: isIPad ? 18 : 14) {
            // Left column
            VStack(spacing: isIPad ? 18 : 14) {
                // Live indicator with equalizer
                liveIndicatorWidget
                // File player bar (if file playing)
                filePlayerWidget
            }
            .frame(maxWidth: .infinity)

            // iPod click wheel
            clickWheel
        }
    }

    // MARK: - Live Indicator Widget

    private var liveIndicatorWidget: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if radioPlayer.isRadioPlaying {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 8, height: 8)
                        .shadow(color: AppColors.success.opacity(0.5), radius: 4)
                }

                Text(radioPlayer.isRadioPlaying ? "В ЭФИРЕ" : "ОФЛАЙН")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(radioPlayer.isRadioPlaying ? AppColors.accentAdaptive : AppColors.textSecondary)
                    .tracking(1.5)
            }

            // Equalizer visualization
            MiniEqualizerView(isPlaying: radioPlayer.isRadioPlaying)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIPad ? 80 : 65)
        .neumorphicRaised(cornerRadius: 16)
    }

    // MARK: - File Player Widget

    @ViewBuilder
    private var filePlayerWidget: some View {
        if radioPlayer.activeMode == .file,
           let track = radioPlayer.filePlayer.currentTrack {
            VStack(spacing: 4) {
                Image(systemName: "music.note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accentAdaptive)
                Text(track.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 80 : 65)
            .neumorphicRaised(cornerRadius: 16)
        } else {
            VStack(spacing: 4) {
                Image(systemName: "headphones")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 80 : 65)
            .neumorphicRaised(cornerRadius: 16)
        }
    }

    // MARK: - iPod Click Wheel

    private var clickWheel: some View {
        let wheelSize: CGFloat = isIPad ? 180 : 150
        let centerSize: CGFloat = isIPad ? 64 : 52

        return ZStack {
            // Wheel background
            Circle()
                .fill(AppColors.background)
                .frame(width: wheelSize, height: wheelSize)
                .shadow(color: AppColors.shadowDark, radius: 10, x: 6, y: 6)
                .shadow(color: AppColors.shadowLight, radius: 10, x: -6, y: -6)

            // Menu dots (top)
            Button(action: {}) {
                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        ForEach(0..<2, id: \.self) { _ in
                            Circle().fill(AppColors.textPrimary.opacity(0.4))
                                .frame(width: 4, height: 4)
                        }
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<2, id: \.self) { _ in
                            Circle().fill(AppColors.textPrimary.opacity(0.4))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .offset(y: -wheelSize * 0.28)

            // Rewind (left)
            Button(action: {
                HapticManager.lightImpact()
                radioPlayer.playPrevious()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.5))
            }
            .offset(x: -wheelSize * 0.28)

            // Forward (right)
            Button(action: {
                HapticManager.lightImpact()
                radioPlayer.playNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.5))
            }
            .offset(x: wheelSize * 0.28)

            // Pause indicator (bottom)
            Image(systemName: "pause.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textPrimary.opacity(0.4))
                .offset(y: wheelSize * 0.28)

            // Center play/stop button
            Button(action: {
                HapticManager.mediumImpact()
                radioPlayer.toggleRadio()
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: centerSize, height: centerSize)
                        .shadow(color: AppColors.shadowDark.opacity(0.4), radius: 4, x: 2, y: 2)
                        .shadow(color: AppColors.shadowLight.opacity(0.8), radius: 4, x: -2, y: -2)

                    Image(systemName: radioPlayer.isRadioPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: isIPad ? 22 : 18, weight: .medium))
                        .foregroundStyle(radioPlayer.isRadioPlaying ? AppColors.accentAdaptive : AppColors.textPrimary)
                        .offset(x: radioPlayer.isRadioPlaying ? 0 : 2)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(NeumorphicButtonStyle())

            // Decorative dots (bottom right of wheel)
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(AppColors.textSecondary.opacity(0.15))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            .offset(x: wheelSize * 0.42, y: wheelSize * 0.42)
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
                .font(.system(size: 13, weight: .medium, design: .rounded))
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
