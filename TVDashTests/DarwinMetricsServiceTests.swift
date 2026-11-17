import Foundation
import Testing

@testable import TVDash

/// Smoke tests against the real system calls, so a broken Mach or sysctl call is caught before it reaches a device.
@Suite("DarwinMetricsService")
struct DarwinMetricsServiceTests {
    @Test func snapshotReadsTheSystem() async throws {
        let snapshot = await DarwinMetricsService().snapshot()

        let memory = try #require(snapshot.memory)
        #expect(memory.total > 0)
        #expect(memory.available <= memory.total)
        #expect(!snapshot.cores.isEmpty)
        let process = try #require(snapshot.process)
        #expect(process.threadCount > 0)
        #expect(process.memoryFootprint > 0)
        let boot = try #require(snapshot.bootDate)
        #expect(boot < .now)
    }

    @Test func storageReadsTheVolume() async throws {
        let storage = try #require(await DarwinMetricsService().storage())

        #expect(storage.volumeTotal > 0)
        #expect(storage.appBundle > 0)
    }

    @Test func deviceInfoIsFilledIn() {
        let info = DarwinMetricsService().deviceInfo()

        #expect(!info.systemVersion.isEmpty)
        #expect(!info.modelIdentifier.isEmpty)
        #expect(info.processorCount > 0)
    }
}

@Suite("DashboardModel with real services")
struct DashboardModelLiveTests {
    @Test func monitorDeliversMeasurements() async throws {
        let model = DashboardModel()

        let task = Task { await model.monitor() }
        let deadline = Date.now.addingTimeInterval(5)
        while model.memory == nil || model.path == nil, Date.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        task.cancel()

        #expect(model.memory != nil)
        #expect(model.path != nil)
    }
}
