import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isLandscape: Bool { vSizeClass == .compact }
    private var player: FilePlayerService { radioPlayer.filePlayer }
    private var progress: Double {
        player.duration > 0 ? player.currentTime / player.duration : 0
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header

                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
        }
    }

    // MARK: - Background — blurred artwork halo

    private var backgroundLayer: some View {
        ZStack {
            AppColors.background
            if let track = player.currentTrack {
                ArtworkViewBlurredBackground(url: track.url)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header — minimal: drag handle + close

    private var header: some View {
        HStack(spacing: 8) {
            // Top drag handle (decorative)
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.textSecondary.opacity(0.25))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.leading, 44)
                .padding(.trailing, 0)

            Button {
                HapticManager.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isLandscape ? 6 : 10)
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            heroArtwork(size: 280)

            Spacer(minLength: 24)

            trackTitleBlock
                .padding(.horizontal, 32)

            Spacer(minLength: 18)

            seekSlider
                .padding(.horizontal, 32)

            Spacer(minLength: 22)

            transportControls
                .padding(.horizontal, 32)

            Spacer(minLength: 22)

            utilityRow
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        HStack(spacing: 28) {
            heroArtwork(size: 180)
                .padding(.leading, 16)

            VStack(spacing: 14) {
                Spacer()
                trackTitleBlock
                seekSlider
                transportControls
                utilityRow
                Spacer()
            }
            .frame(maxWidth: 360)
            .padding(.trailing, 16)
        }
    }

    // MARK: - Hero artwork (square with thin progress ring)

    private func heroArtwork(size: CGFloat) -> some View {
        let ringSize = size + 26
        return ZStack {
            // Thin progress ring around artwork — matches the gold accent
            Circle()
                .stroke(AppColors.stroke, lineWidth: 3)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppGradients.accentGradient,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.4), value: progress)

            if let track = player.currentTrack {
                ArtworkViewFrosted(url: track.url, size: size)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.18), radius: 28, y: 14)
            }
        }
    }

    // MARK: - Track Title

    private var trackTitleBlock: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.title ?? "")
                .font(.system(size: isLandscape ? 18 : 22, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("SPBChurch Radio")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Seek slider

    private var seekSlider: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.textSecondary.opacity(0.18))
                        .frame(height: 4)

                    Capsule()
                        .fill(AppGradients.accentGradient)
                        .frame(width: max(0, geo.size.width * progress), height: 4)

                    Circle()
                        .fill(AppColors.accentAdaptive)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .shadow(color: AppColors.accent.opacity(0.4), radius: 4, y: 2)
                        .offset(x: max(0, geo.size.width * progress - 7))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newProgress = max(0, min(1, value.location.x / geo.size.width))
                            player.seek(to: newProgress * player.duration)
                        }
                )
            }
            .frame(height: 14)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(formatTime(player.duration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Transport controls

    private var transportControls: some View {
        HStack(spacing: 0) {
            Spacer()

            Button {
                HapticManager.lightImpact()
                radioPlayer.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())
            }

            Spacer()

            Button {
                HapticManager.mediumImpact()
                radioPlayer.toggleFilePause()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppGradients.accentGradient)
                        .frame(width: 88, height: 88)
                        .shadow(color: AppColors.accent.opacity(0.45), radius: 18, y: 8)

                    Image(systemName: radioPlayer.isFilePlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(PressEffectButtonStyle())

            Spacer()

            Button {
                HapticManager.lightImpact()
                radioPlayer.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())
            }

            Spacer()
        }
    }

    // MARK: - Utility row — order, favorite, actions

    private var utilityRow: some View {
        HStack(spacing: 0) {
            // Playback order (cycles shuffle / repeatAll / playOnce)
            Button {
                HapticManager.selection()
                player.order = player.order.next
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: player.order.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.accentAdaptive)
                        .contentTransition(.symbolEffect(.replace))
                    Text(player.order.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Favorite
            if let track = player.currentTrack {
                let isFav = favoritesManager.isFavorite(track)
                Button {
                    HapticManager.mediumImpact()
                    favoritesManager.toggle(track)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isFav ? AppColors.accentAdaptive : AppColors.textPrimary)
                            .symbolEffect(.bounce, value: isFav)
                        Text("Любимые")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Actions menu (download / share / remove download)
            trackActionsMenu
        }
    }

    @ViewBuilder
    private var trackActionsMenu: some View {
        if let track = player.currentTrack {
            let isFav = favoritesManager.isFavorite(track)
            let localURL = downloadManager.localURL(for: track)
            let isDownloaded = localURL != nil
            let isDownloading: Bool = {
                if case .downloading = downloadManager.downloads[track.url] { return true }
                return false
            }()

            Menu {
                Button {
                    HapticManager.lightImpact()
                    favoritesManager.toggle(track)
                } label: {
                    Label(
                        isFav ? "Убрать из избранного" : "Добавить в избранное",
                        systemImage: isFav ? "heart.slash" : "heart"
                    )
                }

                if isDownloaded, let url = localURL {
                    ShareLink(
                        item: url,
                        preview: SharePreview(track.title, image: Image(systemName: "music.note"))
                    ) {
                        Label("Поделиться файлом", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        HapticManager.lightImpact()
                        downloadManager.deleteDownload(track)
                    } label: {
                        Label("Удалить загрузку", systemImage: "trash")
                    }
                } else if isDownloading {
                    Button {
                        HapticManager.lightImpact()
                        downloadManager.cancelDownload(track)
                    } label: {
                        Label("Отменить загрузку", systemImage: "xmark.circle")
                    }
                } else {
                    Button {
                        HapticManager.mediumImpact()
                        downloadManager.download(track)
                    } label: {
                        Label("Скачать трек", systemImage: "arrow.down.circle")
                    }
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Ещё")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .simultaneousGesture(TapGesture().onEnded { HapticManager.lightImpact() })
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

// MARK: - Blurred background artwork

private struct ArtworkViewBlurredBackground: View {
    let url: URL
    @State private var image: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 50)
                    .overlay(
                        colorScheme == .dark
                        ? Color.black.opacity(0.55)
                        : AppColors.background.opacity(0.65)
                    )
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if let cached = ArtworkService.shared.cachedArtwork(for: url) {
                image = cached
            } else {
                ArtworkService.shared.artwork(for: url) { img in image = img }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: image != nil)
    }
}
