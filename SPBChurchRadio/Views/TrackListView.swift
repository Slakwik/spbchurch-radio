import SwiftUI

struct TrackListView: View {
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if trackListVM.isLoading {
                    loadingState
                } else if let error = trackListVM.errorMessage {
                    errorState(message: error)
                } else {
                    trackList
                }
            }
            .navigationTitle("Треки")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $trackListVM.searchText, prompt: "Поиск по названию")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { sortMenu }
            }
            .tint(AppColors.accentAdaptive)
            .onAppear { trackListVM.loadTracks() }
        }
    }

    private var trackList: some View {
        List {
            // Counter row
            if !trackListVM.filteredTracks.isEmpty {
                HStack {
                    Text("\(trackListVM.filteredTracks.count) ТРЕКОВ")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                }
                .listRowInsets(EdgeInsets(top: 0, leading: hSizeClass == .regular ? 28 : 18, bottom: 6, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(trackListVM.filteredTracks) { track in
                TrackRow(track: track)
                    .listRowInsets(EdgeInsets(top: 4, leading: hSizeClass == .regular ? 28 : 18, bottom: 4, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { trackListVM.refresh() }
    }

    // MARK: - Sort menu

    private var sortMenu: some View {
        Menu {
            Picker("Сортировка", selection: $trackListVM.sortOrder) {
                ForEach(TrackListViewModel.SortOrder.allCases) { order in
                    Label(order.displayName, systemImage: order.iconName).tag(order)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: trackListVM.sortOrder.iconName)
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(AppColors.accentAdaptive)
        }
        .onChange(of: trackListVM.sortOrder) { _, _ in HapticManager.selection() }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in PulsingDot(delay: Double(i) * 0.3) }
            }
            Text("Загрузка треков…")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                HapticManager.lightImpact()
                trackListVM.refresh()
            } label: {
                Text("Повторить")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppGradients.accentGradient))
            }
        }
        .padding()
    }
}

// MARK: - Pulsing Dot

private struct PulsingDot: View {
    let delay: Double
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(AppColors.accentAdaptive)
            .frame(width: 9, height: 9)
            .scaleEffect(isPulsing ? 1.3 : 0.7)
            .opacity(isPulsing ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Track Row

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var radioPlayer: RadioPlayerViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var trackListVM: TrackListViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.colorScheme) private var colorScheme

    private var isCurrent: Bool { radioPlayer.filePlayer.currentTrack?.url == track.url }
    private var isPlaying: Bool { isCurrent && radioPlayer.isFilePlaying }
    private var isFavorite: Bool { favoritesManager.isFavorite(track) }
    private var isDownloaded: Bool { downloadManager.isDownloaded(track) }

    var body: some View {
        Button(action: play) {
            HStack(spacing: 14) {
                statusGlyph

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? AppColors.accentAdaptive : AppColors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if isDownloaded {
                            Label("Загружен", systemImage: "arrow.down.circle.fill")
                                .font(.system(size: 11, weight: .medium))
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.accentAdaptive)
                        }
                    }
                }

                Spacer(minLength: 4)

                actionsCluster
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .auroraSolid(cornerRadius: 16)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.accentAdaptive.opacity(isCurrent ? 0.5 : 0), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: isCurrent)
        .contextMenu {
            if let localURL = downloadManager.localURL(for: track) {
                ShareLink(item: localURL,
                          preview: SharePreview(track.title, image: Image(systemName: "music.note"))) {
                    Label("Поделиться файлом", systemImage: "square.and.arrow.up")
                }
            }
            Button { favoritesManager.toggle(track) } label: {
                Label(
                    isFavorite ? "Убрать из избранного" : "Добавить в избранное",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
        }
    }

    private var statusGlyph: some View {
        ZStack {
            Circle()
                .fill(isCurrent ? AppColors.accentTinted : AppColors.background)
                .frame(width: 38, height: 38)
                .overlay {
                    Circle().strokeBorder(AppColors.stroke, lineWidth: 1)
                }

            if isPlaying {
                MiniEqualizerView(isPlaying: true, maxHeight: 14)
            } else if isCurrent {
                Image(systemName: "pause.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.accentAdaptive)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var actionsCluster: some View {
        HStack(spacing: 14) {
            // Favorite toggle
            Button {
                HapticManager.lightImpact()
                favoritesManager.toggle(track)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFavorite ? AppColors.accentAdaptive : AppColors.textSecondary.opacity(0.7))
                    .symbolEffect(.bounce, value: isFavorite)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Download / progress
            downloadGlyph

            // Play
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppGradients.accentGradient))
                .shadow(color: AppColors.accent.opacity(0.3), radius: 6, y: 2)
        }
    }

    @ViewBuilder
    private var downloadGlyph: some View {
        if isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.success)
                .frame(width: 32, height: 32)
        } else if let state = downloadManager.downloads[track.url] {
            switch state {
            case .downloading(let progress):
                CircularProgressView(progress: progress)
                    .frame(width: 18, height: 18)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.lightImpact()
                        downloadManager.cancelDownload(track)
                    }
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.success)
                    .frame(width: 32, height: 32)
            case .failed:
                Button {
                    HapticManager.lightImpact()
                    downloadManager.download(track)
                } label: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.error)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button {
                HapticManager.lightImpact()
                downloadManager.download(track)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func play() {
        HapticManager.mediumImpact()
        if isPlaying {
            radioPlayer.toggleFilePause()
        } else {
            let localURL = downloadManager.localURL(for: track)
            radioPlayer.playFile(track, localURL: localURL, queue: trackListVM.filteredTracks)
        }
    }
}

// MARK: - Circular progress (used by FavoritesView too)

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppGradients.accentGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
        }
    }
}
