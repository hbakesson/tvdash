import Foundation
import Testing

@testable import TVDash

@Suite("DashboardModel")
struct DashboardModelTests {
    private final class StubMetrics: SystemMetricsProviding {
        var snapshots: [SystemSnapshot] = []
        var storageResult: StorageStats?

        func deviceInfo() -> DeviceInfo { PreviewMetrics().deviceInfo() }

        func snapshot() async -> SystemSnapshot {
            snapshots.isEmpty ? makeSnapshot() : snapshots.removeFirst()
        }

        func storage() async -> StorageStats? { storageResult }
    }

    private struct StubPaths: NetworkPathMonitoring {
        let path: NetworkPathInfo

        func paths() -> AsyncStream<NetworkPathInfo> {
            AsyncStream { continuation in
                continuation.yield(path)
                continuation.finish()
            }
        }
    }

    private static let path = NetworkPathInfo(
        status: .connected, medium: .wifi, isExpensive: false, isConstrained: false, supportsIPv4: true,
        supportsIPv6: false, supportsDNS: true, gateways: ["10.0.0.1"]
    )

    private func makeModel(_ metrics: StubMetrics = StubMetrics()) -> DashboardModel {
        DashboardModel(provider: metrics, pathMonitor: StubPaths(path: Self.path))
    }

    @Test func ratesNeedTwoSamples() {
        let model = makeModel()

        model.apply(makeSnapshot(cores: [CoreTicks(user: 0, system: 0, idle: 0, nice: 0)]))

        #expect(model.cpu == nil)
        #expect(model.throughput == nil)
        #expect(model.cpuHistory.samples.isEmpty)
    }

    @Test func derivesCPULoadAndThroughputFromConsecutiveSamples() {
        let model = makeModel()
        let idle = CoreTicks(user: 0, system: 0, idle: 0, nice: 0)

        model.apply(makeSnapshot(cores: [idle, idle], counters: ["en0": .init(bytesIn: 0, bytesOut: 0)]))
        model.apply(
            makeSnapshot(
                at: 2,
                cores: [
                    CoreTicks(user: 50, system: 0, idle: 50, nice: 0),
                    CoreTicks(user: 0, system: 0, idle: 100, nice: 0),
                ],
                counters: ["en0": .init(bytesIn: 2_000, bytesOut: 500)]
            )
        )

        #expect(model.coreLoads.map(\.total) == [0.5, 0])
        #expect(model.cpu?.total == 0.25)
        #expect(model.throughput == NetworkThroughput(bytesInPerSecond: 1_000, bytesOutPerSecond: 250))
        #expect(model.cpuHistory.latest == 0.25)
        #expect(model.downloadHistory.latest == 8_000)
        #expect(model.uploadHistory.latest == 2_000)
    }

    @Test func recordsMemoryHistoryFromTheFirstSample() {
        let model = makeModel()
        let memory = MemoryStats(total: 100, free: 50, active: 50, inactive: 0, wired: 0, compressed: 0)

        model.apply(makeSnapshot(memory: memory))

        #expect(model.memory == memory)
        #expect(model.memoryHistory.latest == 0.5)
    }

    @Test func uptimeRunsFromBootToLatestSample() throws {
        let model = makeModel()
        let boot = referenceDate.addingTimeInterval(-3600)

        model.apply(makeSnapshot(bootDate: boot))

        let uptime = try #require(model.uptime)
        #expect(uptime.lowerBound == boot)
        #expect(uptime.upperBound == referenceDate)
    }

    @Test func totalsTrafficSinceBoot() throws {
        let model = makeModel()

        model.apply(
            makeSnapshot(counters: ["en0": .init(bytesIn: 10, bytesOut: 1), "en1": .init(bytesIn: 5, bytesOut: 2)])
        )

        let traffic = try #require(model.trafficSinceBoot)
        #expect(traffic.received == 15)
        #expect(traffic.sent == 3)
    }

    @Test func storageRefreshKeepsLastValueWhenReadFails() async {
        let metrics = StubMetrics()
        let model = makeModel(metrics)
        let storage = StorageStats(
            volumeTotal: 10, volumeAvailable: 5, appBundle: 1, documents: 0, applicationSupport: 0, caches: 0,
            temporary: 0
        )

        metrics.storageResult = storage
        await model.refreshStorage()
        metrics.storageResult = nil
        await model.refreshStorage()

        #expect(model.storage == storage)
    }

    @Test func refreshTakesASample() async {
        let metrics = StubMetrics()
        metrics.snapshots = [makeSnapshot(at: 5)]
        let model = makeModel(metrics)

        await model.refresh()

        #expect(model.updatedAt == referenceDate.addingTimeInterval(5))
    }

    @Test func monitorFollowsTheNetworkPath() async {
        let model = makeModel()

        let task = Task { await model.monitor() }
        while model.path == nil { await Task.yield() }
        task.cancel()

        #expect(model.path == Self.path)
    }
}
