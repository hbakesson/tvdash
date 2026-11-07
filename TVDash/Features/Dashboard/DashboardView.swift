import SwiftUI

/// Root dashboard screen: a grid of focusable tiles, designed for 10-foot viewing.
struct DashboardView: View {
    @Bindable var model: DashboardModel

    private let columns = [GridItem(.adaptive(minimum: 380), spacing: 48)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 48) {
                    ForEach(model.tiles) { tile in
                        Button {
                            model.select(tile)
                        } label: {
                            DashboardTileView(tile: tile)
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
            }
            .navigationTitle("TVDash")
        }
    }
}

private struct DashboardTileView: View {
    let tile: DashboardTile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: tile.systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(tile.title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(tile.value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .padding(32)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DashboardView(model: DashboardModel())
}
