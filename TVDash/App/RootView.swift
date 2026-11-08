import SwiftUI

/// Top-level navigation: one tab for the OMXS30 chart, then one tab per market region.
///
/// Each region tab has its own navigation stack; selecting an index there opens its chart.
/// Menu/Back on the Siri Remote returns to the table.
///
/// Swipe left/right on the Siri Remote while the tab bar is focused to change screen.
/// The selected tab is remembered, so the app reopens where you left it.
struct RootView: View {
    let indexOverview: IndexOverviewModel
    let markets: MarketsModel

    /// `"overview"` or a `MarketRegion.ID` raw value. Can be overridden at launch with `-selectedTab <value>`.
    @AppStorage("selectedTab") private var selectedTab = RootView.overviewTab

    private static let overviewTab = "overview"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Self.overviewTab) {
                IndexOverviewView(model: indexOverview)
            } label: {
                Text(verbatim: indexOverview.displayName)
            }

            ForEach(markets.regions) { region in
                Tab(value: region.id.rawValue) {
                    NavigationStack {
                        MarketRegionView(region: region, model: markets)
                            .navigationDestination(for: MarketIndex.self) { index in
                                IndexChartScreen(index: index)
                            }
                    }
                } label: {
                    Text(region.title)
                }
            }
        }
        .task { await markets.refreshPeriodically() }
    }
}

/// Owns the chart model for an index opened from a region screen, for as long as the screen is shown.
private struct IndexChartScreen: View {
    @State private var model: IndexOverviewModel

    init(index: MarketIndex) {
        _model = State(initialValue: IndexOverviewModel(symbol: index.symbol, displayName: index.name))
    }

    var body: some View {
        IndexOverviewView(model: model)
    }
}
