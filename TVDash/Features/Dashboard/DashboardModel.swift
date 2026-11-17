import Foundation
import OSLog
import Observation

private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "Dashboard")

/// Live system measurements for every dashboard screen, refreshed while the app is visible.
///
/// Rates (CPU load, network throughput) need two samples, so they appear from the second sample on.
@Observable
final class DashboardModel {
    static let sampleInterval: Duration = .seconds(2)
    /// Disk usage changes slowly and is expensive to measure.
    static let storageInterval: Duration = .seconds(60)
    /// Two minutes of history at the sample interval.
    static let historyLength = 60

    let device: DeviceInfo
    private(set) var latest: SystemSnapshot?
    private(set) var cpu: CPULoad?
    private(set) var coreLoads: [CPULoad] = []
    private(set) var throughput: NetworkThroughput?
    private(set) var storage: StorageStats?
    private(set) var path: NetworkPathInfo?

    private(set) var cpuHistory = RollingHistory<Double>(capacity: historyLength)
    private(set) var memoryHistory = RollingHistory<Double>(capacity: historyLength)
    private(set) var downloadHistory = RollingHistory<Double>(capacity: historyLength)
    private(set) var uploadHistory = RollingHistory<Double>(capacity: historyLength)

    private let provider: any SystemMetricsProviding
    private let pathMonitor: any NetworkPathMonitoring

    init(
        provider: any SystemMetricsProviding = DarwinMetricsService(),
        pathMonitor: any NetworkPathMonitoring = NetworkPathService()
    ) {
        self.provider = provider
        self.pathMonitor = pathMonitor
        self.device = provider.deviceInfo()
    }

    var memory: MemoryStats? { latest?.memory }
    var process: AppProcessStats? { latest?.process }
    var interfaces: [NetworkInterface] { latest?.interfaces ?? [] }
    var thermalState: ThermalState? { latest?.thermalState }
    var bootDate: Date? { latest?.bootDate }
    var updatedAt: Date? { latest?.date }

    /// Time since the last restart, as of the latest sample.
    var uptime: Range<Date>? {
        guard let bootDate, let updatedAt, bootDate <= updatedAt else { return nil }
        return bootDate..<updatedAt
    }

    /// Bytes received and sent on Ethernet and Wi-Fi since the last restart (modulo 4 GiB per interface).
    var trafficSinceBoot: (received: UInt64, sent: UInt64)? {
        guard let counters = latest?.counters, !counters.isEmpty else { return nil }
        return counters.values.reduce((0, 0)) { ($0.0 + UInt64($1.bytesIn), $0.1 + UInt64($1.bytesOut)) }
    }

    /// Takes one sample now.
    func refresh() async {
        apply(await provider.snapshot())
    }

    func refreshStorage() async {
        if let storage = await provider.storage() {
            self.storage = storage
        }
    }

    /// Adds a sample and derives rates from the previous one.
    func apply(_ snapshot: SystemSnapshot) {
        if let previous = latest {
            let seconds = snapshot.date.timeIntervalSince(previous.date)
            coreLoads = CPULoad.perCore(from: previous.cores, to: snapshot.cores)
            let cpu = CPULoad.average(of: coreLoads)
            self.cpu = cpu
            let throughput = NetworkThroughput(from: previous.counters, to: snapshot.counters, over: seconds)
            self.throughput = throughput

            cpuHistory.append(cpu.total, at: snapshot.date)
            downloadHistory.append(throughput.bytesInPerSecond * 8, at: snapshot.date)
            uploadHistory.append(throughput.bytesOutPerSecond * 8, at: snapshot.date)
        }
        if let memory = snapshot.memory {
            memoryHistory.append(memory.usedFraction, at: snapshot.date)
        }
        latest = snapshot
    }

    func update(path: NetworkPathInfo) {
        self.path = path
    }

    /// Samples, measures storage and follows the network path until the calling task is cancelled.
    func monitor() async {
        logger.info("Monitoring started")
        defer { logger.info("Monitoring stopped") }
        await withDiscardingTaskGroup { group in
            group.addTask { await self.sampleContinuously() }
            group.addTask { await self.measureStorageContinuously() }
            group.addTask { await self.followPath() }
        }
    }

    private func sampleContinuously() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: Self.sampleInterval)
        }
    }

    private func measureStorageContinuously() async {
        while !Task.isCancelled {
            await refreshStorage()
            try? await Task.sleep(for: Self.storageInterval)
        }
    }

    private func followPath() async {
        for await path in pathMonitor.paths() {
            update(path: path)
        }
    }
}
