import Foundation

/// Bytes sent and received on one network interface since the device started.
///
/// The kernel reports these as 32-bit counters that wrap around at 4 GiB.
nonisolated struct InterfaceCounters: Equatable, Sendable {
    var bytesIn: UInt32
    var bytesOut: UInt32
}

/// Transfer rate in bytes per second.
nonisolated struct NetworkThroughput: Equatable, Sendable {
    var bytesInPerSecond: Double
    var bytesOutPerSecond: Double

    static let zero = NetworkThroughput(bytesInPerSecond: 0, bytesOutPerSecond: 0)

    /// The combined rate of every interface present in both samples.
    ///
    /// Interfaces that appear or disappear between samples are ignored, so a reconnect does not show a spike.
    init(from old: [String: InterfaceCounters], to new: [String: InterfaceCounters], over seconds: Double) {
        guard seconds > 0 else {
            self = .zero
            return
        }
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        for (name, counters) in new {
            guard let previous = old[name] else { continue }
            bytesIn += UInt64(counters.bytesIn &- previous.bytesIn)
            bytesOut += UInt64(counters.bytesOut &- previous.bytesOut)
        }
        self.init(bytesInPerSecond: Double(bytesIn) / seconds, bytesOutPerSecond: Double(bytesOut) / seconds)
    }

    init(bytesInPerSecond: Double, bytesOutPerSecond: Double) {
        self.bytesInPerSecond = bytesInPerSecond
        self.bytesOutPerSecond = bytesOutPerSecond
    }
}

/// A network interface with its IP addresses.
nonisolated struct NetworkInterface: Equatable, Sendable, Identifiable {
    var name: String
    var ipv4: [String]
    var ipv6: [String]

    var id: String { name }
}
