import SwiftUI

/// Displays album artwork from an MP3 URL, with fallback icon — neumorphic style
struct ArtworkView: View {
    let url: URL
    let size: CGFloat
    var cornerRadius: CGFloat = 10
    @Environment(\.colorScheme) private var colorScheme

    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.surface)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive.opacity(0.3))
                }
                .frame(width: size, height: size)
            }
        }
        .onAppear {
            guard !loaded else { return }
            if let cached = ArtworkService.shared.cachedArtwork(for: url) {
                image = cached
                loaded = true
            } else {
                ArtworkService.shared.artwork(for: url) { img in
                    image = img
                    loaded = true
                }
            }
        }
    }
}

/// Circular frosted artwork for the neumorphic Now Playing style
struct ArtworkViewFrosted: View {
    let url: URL
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colorScheme == .dark
                                    ? Color(red: 0.18, green: 0.18, blue: 0.22)
                                    : Color(red: 0.95, green: 0.95, blue: 0.97),
                                    colorScheme == .dark
                                    ? Color(red: 0.12, green: 0.12, blue: 0.16)
                                    : Color(red: 0.88, green: 0.88, blue: 0.92)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.25, weight: .medium))
                        .foregroundStyle(AppColors.accentAdaptive.opacity(0.25))
                }
                .frame(width: size, height: size)
            }
        }
        .onAppear {
            guard !loaded else { return }
            if let cached = ArtworkService.shared.cachedArtwork(for: url) {
                image = cached
                loaded = true
            } else {
                ArtworkService.shared.artwork(for: url) { img in
                    image = img
                    loaded = true
                }
            }
        }
    }
}

/// Dark-themed artwork for legacy compatibility
struct ArtworkViewDark: View {
    let url: URL
    let size: CGFloat

    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        ArtworkViewFrosted(url: url, size: size)
    }
}
