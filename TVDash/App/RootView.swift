import SwiftUI

/// Top-level navigation: an overview tab followed by one tab per category.
///
/// Swipe left/right on the Siri Remote while the tab bar is focused to change category. The selected tab is
/// remembered, so the app reopens where you left it. Measurements run while this view is on screen.
struct RootView: View {
    let dashboard: DashboardModel
    let speedTest: SpeedTestModel

    /// Can be overridden at launch with `-selectedSection <raw value>`.
    @AppStorage("selectedSection") private var selection = DashboardSection.overview

    var body: some View {
        TabView(selection: $selection) {
            ForEach(DashboardSection.allCases) { section in
                Tab(value: section) {
                    screen(for: section)
                } label: {
                    // Text only: six labels with icons do not fit in the tvOS tab bar.
                    Text(section.title)
                }
            }
        }
        // On a plain container rather than the TabView itself: tvOS does not run `.task` attached to a TabView.
        .background { Color.clear.task { await dashboard.monitor() } }
    }

    @ViewBuilder
    private func screen(for section: DashboardSection) -> some View {
        switch section {
        case .overview: OverviewView(model: dashboard, selection: $selection)
        case .memory: MemoryView(model: dashboard)
        case .storage: StorageView(model: dashboard)
        case .processor: ProcessorView(model: dashboard)
        case .network: NetworkView(model: dashboard, speedTest: speedTest)
        case .system: SystemView(model: dashboard)
        }
    }
}

#Preview {
    RootView(
        dashboard: DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor()),
        speedTest: SpeedTestModel(service: PreviewSpeedTest())
    )
}
