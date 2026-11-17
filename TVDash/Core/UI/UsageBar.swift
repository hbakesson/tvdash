import SwiftUI

/// A horizontal bar split into coloured segments, e.g. how RAM or disk space is used.
struct UsageBar: View {
    struct Segment: Identifiable {
        let label: LocalizedStringKey
        let fraction: Double
        let color: Color

        var id: String { "\(color)-\(fraction)" }
    }

    let segments: [Segment]
    var height: CGFloat = 28

    /// A single filled segment over an empty track.
    init(fraction: Double, color: Color, height: CGFloat = 28) {
        self.segments = [Segment(label: "", fraction: fraction, color: color)]
        self.height = height
    }

    init(segments: [Segment], height: CGFloat = 28) {
        self.segments = segments
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color.gradient)
                        .frame(width: geometry.size.width * Self.clamped(segment.fraction))
                }
                Spacer(minLength: 0)
            }
            .background(Color.primary.opacity(0.12))
            .clipShape(Capsule())
            .animation(.easeOut(duration: 0.4), value: segments.map(\.fraction))
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private static func clamped(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }
}

/// Colour key for a segmented `UsageBar`.
struct UsageLegend: View {
    let segments: [UsageBar.Segment]

    var body: some View {
        HStack(spacing: 32) {
            ForEach(segments) { segment in
                HStack(spacing: 10) {
                    Circle().fill(segment.color).frame(width: 18, height: 18)
                    Text(segment.label)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    VStack(spacing: 40) {
        UsageBar(fraction: 0.62, color: .orange)
        UsageBar(segments: [
            .init(label: "Wired", fraction: 0.2, color: .red),
            .init(label: "Active", fraction: 0.3, color: .purple),
        ])
    }
    .padding(80)
}
