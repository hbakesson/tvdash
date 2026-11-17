import Foundation

// Fake services with plausible numbers, for SwiftUI previews only.

struct PreviewMetrics: SystemMetricsProviding {
    func deviceInfo() -> DeviceInfo {
        DeviceInfo(
            name: "Apple TV", modelIdentifier: "AppleTV18,1", isSimulator: false, systemName: "tvOS",
            systemVersion: "27.2", systemBuild: "24K150", kernelVersion: "27.2.0", processorCount: 6,
            activeProcessorCount: 6, physicalMemory: 4 << 30, appVersion: "0.2.0", appBuild: "1", launchDate: .now
        )
    }

    func snapshot() async -> SystemSnapshot {
        let time = Date.now.timeIntervalSince1970
        let wave = (sin(time / 7) + 1) / 2
        let ticks = UInt32(truncatingIfNeeded: Int(time * 100))
        return SystemSnapshot(
            date: .now,
            memory: MemoryStats(
                total: 4 << 30, free: 300 << 20, active: 1500 << 20, inactive: 900 << 20,
                wired: 800 << 20, compressed: 300 << 20
            ),
            cores: (0..<6).map { core in
                let busy = ticks / UInt32(core + 2)
                return CoreTicks(user: busy, system: busy / 3, idle: ticks, nice: 0)
            },
            process: AppProcessStats(
                processID: 412, threadCount: 14, cpuUsage: 0.04, memoryFootprint: 48 << 20,
                memoryAvailable: 1500 << 20
            ),
            counters: [
                "en0": InterfaceCounters(bytesIn: ticks &* UInt32(20_000 + wave * 80_000), bytesOut: ticks &* 900)
            ],
            interfaces: [NetworkInterface(name: "en0", ipv4: ["192.168.1.42"], ipv6: ["2001:db8::42"])],
            bootDate: .now.addingTimeInterval(-3 * 86_400 - 4 * 3600),
            thermalState: .nominal
        )
    }

    func storage() async -> StorageStats? {
        StorageStats(
            volumeTotal: 64_000_000_000, volumeAvailable: 21_500_000_000, appBundle: 6_200_000,
            documents: 0, applicationSupport: 12_000, caches: 2_400_000, temporary: 0
        )
    }
}

struct PreviewPathMonitor: NetworkPathMonitoring {
    func paths() -> AsyncStream<NetworkPathInfo> {
        AsyncStream { continuation in
            continuation.yield(
                NetworkPathInfo(
                    status: .connected, medium: .ethernet, isExpensive: false, isConstrained: false,
                    supportsIPv4: true, supportsIPv6: true, supportsDNS: true, gateways: ["192.168.1.1"]
                )
            )
        }
    }
}

struct PreviewSpeedTest: SpeedTesting {
    func run(progress: @escaping @Sendable (SpeedTestPhase) async -> Void) async throws -> SpeedTestResult {
        for phase in [SpeedTestPhase.latency, .download, .upload] {
            await progress(phase)
            try await Task.sleep(for: .seconds(1))
        }
        return SpeedTestResult(
            latency: .milliseconds(12), downloadBitsPerSecond: 487e6, uploadBitsPerSecond: 93e6, date: .now
        )
    }
}
