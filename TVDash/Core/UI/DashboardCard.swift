import SwiftUI

/// A titled panel on a dashboard screen.
///
/// Cards are focusable by default so the Siri Remote can move through – and scroll – a screen that otherwise has
/// nothing to select. A card that contains its own buttons must pass `isFocusable: false`, because tvOS does not
/// support focusable views inside focusable views.
struct DashboardCard<Content: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    var tint: Color = .accentColor
    var isFocusable = true
    @ViewBuilder let content: Content

    var body: some View {
        if isFocusable {
            chrome.focusable().accessibilityElement(children: .combine)
        } else {
            chrome
        }
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            content
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background { CardBackground(isFocusable: isFocusable) }
    }
}

/// Lifts the card while it has focus. Reads `isFocused` from inside the focusable view.
private struct CardBackground: View {
    let isFocusable: Bool
    @Environment(\.isFocused) private var isFocused

    private var highlighted: Bool { isFocusable && isFocused }

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.primary.opacity(highlighted ? 0.16 : 0.07))
            .strokeBorder(Color.primary.opacity(highlighted ? 0.35 : 0), lineWidth: 3)
            .shadow(color: .black.opacity(highlighted ? 0.35 : 0), radius: 24, y: 12)
            .scaleEffect(highlighted ? 1.015 : 1)
            .animation(.easeOut(duration: 0.15), value: highlighted)
    }
}

#Preview {
    HStack(spacing: 40) {
        DashboardCard(title: "Memory", systemImage: "memorychip", tint: .purple) {
            InfoRow("Total", value: "4 GB")
            InfoRow("Available", value: "1.2 GB")
        }
        DashboardCard(title: "Network", systemImage: "network", tint: .green, isFocusable: false) {
            Button("Test Speed") {}
        }
    }
    .padding(80)
}
