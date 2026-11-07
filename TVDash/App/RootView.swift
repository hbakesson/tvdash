import SwiftUI

/// Top-level navigation: one tab for OMXS30 this year, then one tab per market region.
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
                    MarketRegionView(region: region, model: markets)
                } label: {
                    Text(region.title)
                }
            }
        }
        .task { await markets.refreshPeriodically() }
    }
}
