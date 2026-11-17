import Foundation

/// Everything sampled from the system at one moment. Rates (CPU load, throughput) are derived from two snapshots.
nonisolated struct SystemSnapshot: Equatable, Sendable {
    var date: Date
    var memory: MemoryStats?
    var cores: [CoreTicks]
    var process: AppProcessStats?
    /// Counters for the physical interfaces (Ethernet and Wi-Fi) only.
    var counters: [String: InterfaceCounters]
    var interfaces: [NetworkInterface]
    var bootDate: Date?
    var thermalState: ThermalState
}

/// Mirrors `ProcessInfo.ThermalState`, as a value type the UI can switch over.
nonisolated enum ThermalState: Equatable, Sendable {
    case nominal, fair, serious, critical

    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .nominal
        }
    }
}
