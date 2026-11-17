import Foundation

/// Reports changes to the network route.
protocol NetworkPathMonitoring: Sendable {
    /// Emits the current path right away and again whenever it changes, until the consuming task is cancelled.
    func paths() -> AsyncStream<NetworkPathInfo>
}
