import SwiftUI

/// Displays album artwork from an MP3 URL, with fallback icon
struct ArtworkView: View {
    let url: URL
    let size: CGFloat
    var cornerRadius: CGFloat = 10

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
                        .foregroundStyle(AppColors.textSecondary.opacity(0.4))
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

/// Dark-themed artwork for Now Playing screen
struct ArtworkViewDark: View {
    let url: URL
    let size: CGFloat

    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.08))
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
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
