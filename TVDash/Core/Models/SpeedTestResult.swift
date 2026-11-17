import Foundation

/// The outcome of one internet speed test.
nonisolated struct SpeedTestResult: Equatable, Sendable {
    /// Round-trip time to the test server.
    var latency: Duration
    var downloadBitsPerSecond: Double
    var uploadBitsPerSecond: Double
    var date: Date

    /// Bits per second for `bytes` transferred in `duration`, or 0 if no time passed.
    static func bitsPerSecond(bytes: Int, duration: Duration) -> Double {
        let seconds = duration.seconds
        return seconds > 0 ? Double(bytes) * 8 / seconds : 0
    }
}

/// Which part of a speed test is running.
nonisolated enum SpeedTestPhase: Equatable, Sendable {
    case latency, download, upload
}

extension Duration {
    nonisolated var seconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
