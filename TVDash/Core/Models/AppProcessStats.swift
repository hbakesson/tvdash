import Foundation

/// Resource use of this app's own process.
///
/// tvOS does not let apps inspect other processes, so this is the only process we can show in detail.
nonisolated struct AppProcessStats: Equatable, Sendable {
    var processID: Int32
    var threadCount: Int
    /// Sum over all threads, where 1.0 is one fully busy core.
    var cpuUsage: Double
    /// Memory the system charges to the app (what counts towards its memory limit).
    var memoryFootprint: UInt64
    /// How much more the app may allocate before tvOS terminates it.
    var memoryAvailable: UInt64

    /// The app's memory limit: what it uses plus what it may still allocate.
    var memoryLimit: UInt64 { memoryFootprint + memoryAvailable }
}
