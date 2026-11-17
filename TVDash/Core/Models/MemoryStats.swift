import Foundation

/// System-wide physical memory, from the kernel's virtual memory statistics.
nonisolated struct MemoryStats: Equatable, Sendable {
    /// Installed RAM.
    var total: UInt64
    /// Pages nobody uses.
    var free: UInt64
    /// Pages in recent use.
    var active: UInt64
    /// Pages not used recently; the system reclaims these first when memory runs low.
    var inactive: UInt64
    /// Pages the kernel has locked in memory.
    var wired: UInt64
    /// Memory occupied by compressed pages.
    var compressed: UInt64

    /// Memory an app could get without the system terminating anything: free plus reclaimable pages.
    var available: UInt64 { min(total, free + inactive) }

    var used: UInt64 { total - available }

    /// `used / total`, between 0 and 1.
    var usedFraction: Double {
        total == 0 ? 0 : Double(used) / Double(total)
    }
}
