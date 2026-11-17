import SwiftUI

/// Common layout for a category screen: a scrolling column of cards below a title.
struct DashboardScreen<Content: View>: View {
    let section: DashboardSection
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Label(section.title, systemImage: section.systemImage)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.primary, section.tint)
                content
            }
            // No horizontal padding: the tab view already insets content to the 80 pt safe area.
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollClipDisabled()
    }
}

/// Two equal-width columns of cards, top-aligned.
struct CardColumns<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(spacing: 40) { leading }
                .frame(maxWidth: .infinity)
            VStack(spacing: 40) { trailing }
                .frame(maxWidth: .infinity)
        }
        .focusSection()
    }
}

/// Explains something tvOS does not let apps see, in place of a missing measurement.
struct PlatformLimitNote: View {
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: "lock.shield")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
