import Foundation

/// Cumulative scheduler ticks for one CPU core, as reported by `host_processor_info`.
///
/// The kernel counters are 32-bit and wrap around, so differences use wrapping arithmetic.
nonisolated struct CoreTicks: Equatable, Sendable {
    var user: UInt32
    var system: UInt32
    var idle: UInt32
    var nice: UInt32
}

/// How busy a CPU (or all CPUs together) was between two samples. Fractions are between 0 and 1.
nonisolated struct CPULoad: Equatable, Sendable {
    var user: Double
    var system: Double

    var total: Double { min(1, user + system) }

    static let idle = CPULoad(user: 0, system: 0)

    /// Load of one core between two tick samples. Returns `.idle` if no time passed.
    init(from old: CoreTicks, to new: CoreTicks) {
        let user = Double(new.user &- old.user) + Double(new.nice &- old.nice)
        let system = Double(new.system &- old.system)
        let idle = Double(new.idle &- old.idle)
        let all = user + system + idle
        guard all > 0 else {
            self = .idle
            return
        }
        self.init(user: user / all, system: system / all)
    }

    init(user: Double, system: Double) {
        self.user = user
        self.system = system
    }

    /// Per-core loads between two samples. Cores missing from either sample are skipped.
    static func perCore(from old: [CoreTicks], to new: [CoreTicks]) -> [CPULoad] {
        zip(old, new).map { CPULoad(from: $0, to: $1) }
    }

    /// The average of several cores, so 1.0 means every core was fully busy.
    static func average(of loads: [CPULoad]) -> CPULoad {
        guard !loads.isEmpty else { return .idle }
        let count = Double(loads.count)
        return CPULoad(
            user: loads.map(\.user).reduce(0, +) / count,
            system: loads.map(\.system).reduce(0, +) / count
        )
    }
}
