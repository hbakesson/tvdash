import SwiftUI

/// App entry point. Keep this file thin: wire up dependencies and the root scene only.
@main
struct TVDashApp: App {
    @State private var indexOverview = IndexOverviewModel()
    @State private var markets = MarketsModel()

    var body: some Scene {
        WindowGroup {
            RootView(indexOverview: indexOverview, markets: markets)
        }
    }
}
