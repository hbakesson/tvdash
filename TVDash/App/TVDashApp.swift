import SwiftUI

/// App entry point. Keep this file thin: wire up dependencies and the root scene only.
@main
struct TVDashApp: App {
    @State private var dashboard = DashboardModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(model: dashboard)
        }
    }
}
