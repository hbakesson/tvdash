import SwiftUI

/// App entry point. Keep this file thin: wire up dependencies and the root scene only.
@main
struct TVDashApp: App {
    @State private var indexOverview = IndexOverviewModel()

    var body: some Scene {
        WindowGroup {
            IndexOverviewView(model: indexOverview)
        }
    }
}
