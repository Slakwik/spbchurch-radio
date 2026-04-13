import SwiftUI

/// Animated audio equalizer bars — responds to isPlaying state
struct AnimatedEqualizerView: View {
    var isPlaying: Bool
    var barCount: Int = 5
    var barWidth: CGFloat = 4
    var barSpacing: CGFloat = 3
    var minHeight: CGFloat = 4
    var maxHeight: CGFloat = 28
    var color: Color = AppColors.accentAdaptive
    var cornerRadius: CGFloat = 2

    @State private var heights: [CGFloat] = []
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: heights[safe: index] ?? minHeight)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6),
                        value: heights
                    )
            }
        }
        .onAppear {
            heights = Array(repeating: minHeight, count: barCount)
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                heights = (0..<barCount).map { _ in
                    CGFloat.random(in: minHeight...maxHeight)
                }
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if !newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    heights = Array(repeating: minHeight, count: barCount)
                }
            }
        }
    }
}

// MARK: - Mini Equalizer (for track rows)

struct MiniEqualizerView: View {
    var isPlaying: Bool
    var barCount: Int = 3
    var barWidth: CGFloat = 2.5
    var maxHeight: CGFloat = 14

    var body: some View {
        AnimatedEqualizerView(
            isPlaying: isPlaying,
            barCount: barCount,
            barWidth: barWidth,
            minHeight: 3,
            maxHeight: maxHeight,
            color: AppColors.accentAdaptive,
            cornerRadius: 1.5
        )
    }
}

// MARK: - Large Equalizer (for radio view)

struct LargeEqualizerView: View {
    var isPlaying: Bool
    var barCount: Int = 7
    var barWidth: CGFloat = 5
    var maxHeight: CGFloat = 36

    var body: some View {
        AnimatedEqualizerView(
            isPlaying: isPlaying,
            barCount: barCount,
            barWidth: barWidth,
            minHeight: 6,
            maxHeight: maxHeight,
            color: AppColors.accentAdaptive,
            cornerRadius: 2.5
        )
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
