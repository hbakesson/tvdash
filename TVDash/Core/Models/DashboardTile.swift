import Foundation

/// A single tile shown on the dashboard.
///
/// Models are plain value types: `Sendable`, `Hashable` and free of UI code,
/// so they can be created in tests and passed across concurrency domains.
struct DashboardTile: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var value: String
    var systemImage: String

    init(id: UUID = UUID(), title: String, value: String, systemImage: String) {
        self.id = id
        self.title = title
        self.value = value
        self.systemImage = systemImage
    }
}

extension DashboardTile {
    /// Sample data for previews and tests.
    static let samples: [DashboardTile] = [
        DashboardTile(title: "Weather", value: "12°", systemImage: "cloud.sun"),
        DashboardTile(title: "Calendar", value: "3 events", systemImage: "calendar"),
        DashboardTile(title: "Transit", value: "4 min", systemImage: "tram"),
        DashboardTile(title: "Energy", value: "1.2 kW", systemImage: "bolt"),
    ]
}
