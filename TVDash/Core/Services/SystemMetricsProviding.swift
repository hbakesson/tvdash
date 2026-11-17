import Foundation

/// Reads live measurements from the system.
///
/// Models depend on this protocol rather than on `DarwinMetricsService`, so tests and previews can supply fixed data.
protocol SystemMetricsProviding: Sendable {
    /// Facts that do not change while the app runs.
    func deviceInfo() -> DeviceInfo
    /// Memory, CPU ticks, network counters and more, sampled now. Cheap enough to call every second or two.
    func snapshot() async -> SystemSnapshot
    /// Disk usage. Walks the app's directories, so call it rarely.
    func storage() async -> StorageStats?
}
